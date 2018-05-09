require "json"
require "selenium-webdriver"
require 'securerandom'
require 'httpclient'
require 'benchmark'
require 'logger'
require 'active_support'
require 'fileutils'
require 'date'
require 'digest/md5'

# サブミットボタンリトライ回数
$submitRetry = 3

# サブミットボタン検索待機秒数
$submitSleep = 0.7

# テキスト入力リトライ回数
$textRetry = 5

# フォーム入力wait時間
$wait = 1

#　エレメント存在確認
def checkElement(d,s)

	# cssセレクタ
	element = d.execute_script("return document.querySelector('" + s + "')")

	# cssセレクタが存在しない場合nameを判定
	unless element then
		element = d.execute_script("return document.getElementsByName('" + s + "')")
	end

	# css,name共に要素が存在しない
	unless element then
		puts "エレメントが存在しない => " + s.to_s
		$log.error("エレメントが存在しない => " + s.to_s)
		raise Selenium::WebDriver::Error::NoSuchElementError
		return false
	end

	return true

end

# input method (CSS)
def inputText(d, s, v,sec=0.5)

	if !checkElement(d,s) then return end

	i = 0;
	for i in 1..$textRetry

		d.find_element(:css, s).click
		d.find_element(:css, s).clear
		d.find_element(:css, s).send_keys v

		#　入力値確認
		text = d.execute_script("return document.querySelector('" + s + "').value;")
		if text == v then
			d.execute_script("document.querySelector('" + s + "').dispatchEvent(new Event('blur'));")
			break
		end
		sleep sec

	end

end

# input method (name)
def inputText_name(d, s, v, sec=0.5)

	if !checkElement(d, s) then return end

	i = 0;
	for i in 1..$textRetry

			d.find_element(:name, s).click
			d.find_element(:name, s).clear
			d.find_element(:name, s).send_keys v

			#入力値を確認する
			text = d.execute_script("return document.getElementsByName('" + s + "')[0].value;")
			if text == v then
				break
			end
			sleep sec

	end

end

def checkBox(d,s,v)

    if !checkElement(d,s) then
            return
    end
    d.find_element(:css, s).click

    for i in 1..$textRetry

            status = d.execute_script("return document.querySelector('" + s + "').checked")
            d.execute_script("document.querySelector('" + s + "').dispatchEvent(new Event('blur'));")
            d.execute_script("document.querySelector('" + s + "').dispatchEvent(new Event('keydown'));")
            d.execute_script("document.querySelector('" + s + "').dispatchEvent(new Event('change'));")
            d.execute_script("document.querySelector('" + s + "').dispatchEvent(new Event('focus'));")
            d.execute_script("document.querySelector('" + s + "').dispatchEvent(new Event('keyup'));")
            puts status

            if status.to_s == v.to_s then
                break
            end

            puts "checkbox 未押下 " + s.to_s

            #　強制チェック
            d.execute_script("document.querySelector('" + s + "').checked = true;")

            sleep $wait
    end

end

def radioButton(d,s,v)

	if !checkElement(d,s) then
		return
	end

	for i in 1..$textRetry
		d.execute_script("document.querySelector('" + s + "').checked = " + v + ";")

		status = d.execute_script("return document.querySelector('" + s + "').checked")

		if status == v then
			d.execute_script("document.querySelector('" + s + "').dispatchEvent(new Event('click'));")
			break
		end
	end

	d.find_element(:css, s).click
	sleep $wait

end

def radioButtonEx(d,s,v)

    if !checkElement(d,s) then
            return
    end
    #d.find_element(:css, s).click

    for i in 1..$textRetry

            d.execute_script("for(i=0;i<document.querySelectorAll('" + s + "').length;i++){if(document.querySelectorAll('" + s + "')[i].value=='"+v+"'){ document.querySelectorAll('" + s + "')[i].checked = true;}}")
            isChk = d.execute_script("for(i=0;i<document.querySelectorAll('" + s + "').length;i++){if(document.querySelectorAll('" + s + "')[i].value=='"+v+"'){ return document.querySelectorAll('" + s + "')[i].checked; }}")

            p isChk

            if isChk then
                    d.execute_script("document.querySelector('" + s + "').dispatchEvent(new Event('click'));")
                    d.execute_script("document.querySelector('" + s + "').dispatchEvent(new Event('keydown'));")
                    d.execute_script("document.querySelector('" + s + "').dispatchEvent(new Event('change'));")
                    d.execute_script("document.querySelector('" + s + "').dispatchEvent(new Event('focus'));")
                    d.execute_script("document.querySelector('" + s + "').dispatchEvent(new Event('keyup'));")
                    d.execute_script("document.querySelector('" + s + "').dispatchEvent(new Event('blur'));")
                    break
            end
    end

    sleep $wait

end

# input select
def selectOption(d, s, v)

	if !checkElement(d,s) then
		return
	end

	d.execute_script("let options = document.querySelectorAll('" + s + " option');Array.from(options).filter(ele => ele.text === '" + v + "')[0].selected = true;")
	d.execute_script("document.querySelector('" + s + "').dispatchEvent(new Event('change'));")
	sleep 0.5

end

def selectOptionEx(d, s, v)

    if !checkElement(d,s) then
		return
    end

    els = d.execute_script("return document.querySelectorAll('" + s + " option');")

    exists = false
    els.each{|el|
        if el.attribute("value") == v then
            exists = true
        end
    }

    if !exists then
        puts "selectOptionEx not found value " + v
        return
    end

    d.execute_script("let options = document.querySelectorAll('" + s + " option');Array.from(options).filter(ele => ele.value === '" + v + "')[0].selected = true;")
    d.execute_script("document.querySelector('" + s + "').dispatchEvent(new Event('change'));")
    sleep 0.5

end

def inputTextArea(d, s, v,sec=0.65)

    if !checkElement(d,s) then
        return
    end

    i = 0;
    for i in 1..$textRetry

        d.find_element(:css, s).click
        d.find_element(:css, s).clear
        d.find_element(:css, s).send_keys v

        # 入力値確認
        text = d.execute_script("return document.querySelector('" + s + "').value;")
        if text == v then
            d.execute_script("document.querySelector('" + s + "').dispatchEvent(new Event('blur'));")
            break
        else
            puts text + " != " + v
        end
        sleep sec

    end

end

def getText(d, s)

	if checkElement(d,s) then
		return d.execute_script("return document.querySelector('" + s + "').innerHTML;")
	else
		puts "Element Not Fount ( getText() ) ======>" + s;
	end

end

# サブミットボタンが見えるまで待機
def waitSubmitVisible(el)

	i = 0;
	for i in 1..$submitRetry

		sleep $submitSleep
		if !checkElement(d,s) then
            #if !el.displayed? then
            next
		end
		break

	end

	if !el.displayed? then
		return false
	end

	el.click
	return true
end


# サブミットボタンが見えるまで待機
def waitSubmitVisibleSelector(d,s)

	$msg = "Processing [waitSubmitVisibleSelector]"
	$log.info($msg)

	i = 0
	el = d.find_element(:css, s)
	for i in 1..$submitRetry

		sleep $submitSleep
		if !checkElement(d,s) then
            $log.error(">> Element not found " + s.to_s)
            next
		end

		el = d.find_element(:css, s)
		if el.displayed? then
			$log.info(">> Click Element Visible " + s.to_s)
			sleep $wait
			break
		end

	end
	d.execute_script("document.querySelector('" + s + "').click();")

	sleep 5
	return true

end

# 特定のタイトルが表示されるまで待機
def waitPage(d,s,text)

	result = false
	begin

		for i in 1..5

			if checkElement(d,s) && d.find_element(:css, s).text == text  then
				result = true
				break;
			end
			sleep 1

		end
		rescue Selenium::WebDriver::Error::StaleElementReferenceError
		puts "Selenium::WebDriver::Error::StaleElementReferenceError"
		sleep 0.5
		retry

	end

	return result

end

##
## 特定のタイトルが表示されるまで待機（文字列検索）
##------------------------------------------------------------------------------------------
def waitPageEx(d, s, text)

		$msg = "Processing [waitPageEx] : " + text
		$log.info($msg)

		result = false
		begin

            # Wait Time 10sec
            $checkRetry = 10
            for i in 1..$checkRetry

                sleep 1
                $log.info(">> Check count " + i.to_s)

                ##-- 要素存在確認
                element = d.execute_script("return document.querySelector('" + s + "')")
                unless element then
                    next
                end

                ##-- テキスト文字列存在確認
                if d.find_element(:css, s).text.include?(text) then
                    result = true
                    break
                end

    		end

		rescue Selenium::WebDriver::Error::StaleElementReferenceError

            puts "ERROR Block"
            $log.error(">> Selenium::WebDriver::Error::StaleElementReferenceError")

		end
		return result

end

def screenShot(d,savepath)

		$msg = "Processing [screenShot]"
		$log.info($msg)

		sleep 1
		### height = d.execute_script("return document.body.clientHeight;");
		height = d.execute_script("return document.documentElement.scrollHeight;");
		count = height / 640
		if count <= 0 then
				count = 0
		end

		# puts "height = " + height.to_s
		d.execute_script("window.scrollTo(0,0);")
		basename = Time.now.strftime("%Y_%m_%d_%H_%M_%S_%L_")

		for i in 0..count

				d.execute_script("window.scrollTo(0," + (i * 640 ).to_s + ");")
				sleep 0.5
				path = File.join(savepath,  basename + "_" + i.to_s + ".png" )
				d.save_screenshot(path)
				sleep 0.5

		end

end

def ss(d,dir)
	screenShot(d,dir)
end

# Error用
def ss_err(d,dir)
	screenShot(d,dir)
end

def postJson(url,json)

	http_client = HTTPClient.new

	p url
	p json

	if url == nil then url = "Nothing" end
	$log.info(url + ":" + json)

	return http_client.post_content(url, json, 'Content-Type' => 'application/json')

end

# ステータスコード生成用
def make_StatusCode(type, seq_id, status, login_id, message)

	day = Time.now
	datetime = Time.now.strftime("%Y-%m-%d %H:%M:%S") #=> "2009-03-01 00:31:21"
	host = `hostname`.strip

	data = {
		"status" => status,
		"seqid" => seq_id,
		"loginid" => login_id,
		"type" => type,
		"date" => datetime,
		"host" => host,
		"message" => message
	}
	return JSON.generate(data)

end

# ステータスコード生成用（例外処理用）
def mr_make_StatusCode(type, seq_id, status, login_id, mr_data, message)

	day = Time.now
	datetime = Time.now.strftime("%Y-%m-%d %H:%M:%S") #=> "2009-03-01 00:31:21"
	host = `hostname`.strip

	data = {
		"status" => status,
		"seqid" => seq_id,
		"loginid" => login_id,
		"mr_data" => mr_data,
		"type" => type,
		"date" => datetime,
		"host" => host,
		"message" => message
	}
	return JSON.generate(data)

end

# ステータスコード生成用
def make_RealTimeCheckStatusCode(type, seq_id, status, login_id, get_data, input_data, err_location, err_time, message)

	day = Time.now
	datetime = Time.now.strftime("%Y-%m-%d %H:%M:%S") #=> "2009-03-01 00:31:21"
	host = `hostname`.strip

	data = {
		"status" => status,
		"seqid" => seq_id,
		"loginid" => login_id,
		"type" => type,
		"date" => datetime,
		"host" => host,
		"get_data" => get_data,
		"input_data" => input_data,
		"err_location" => err_location,
		"err_time" => err_time,
		"message" => message
	}
	return JSON.generate(data)

end

def input(d,s,tag,name,v)

	selector = tag +"[name=\"" + name + "\"]"

	if tag == "input" then
	   inputText(d,selector,v )
	elsif tag == "select" then
		selectOption(d,selector,v)
	elsif tag == "radio" then
		radioButtonEx(d,s,v)
	elsif tag == "checkbox" then
		selector = "input[name=\"" + name + "\"]"
		checkBox(d,selector,v)
	end

end

def set(d,name,v)

    if d == nil || name == nil || v == nil then
        return false
    end

    v = v.to_s
    puts "Form Name =======> " + name + " Value =======> " + v

    if ! d.execute_script("return document.getElementsByName(\"" + name + "\")[0]") then
        return false
    end

    tag = d.execute_script("return document.getElementsByName(\"" + name + "\")[0].tagName")
    disabled = d.execute_script("return document.getElementsByName(\"" + name + "\")[0].disabled")
    readonly = d.execute_script("return document.getElementsByName(\"" + name + "\")[0].readOnly")

    puts tag + " disabled => " + disabled.to_s + " readonly => " + readonly.to_s

    el = d.find_element(:name, name)
    if !el.displayed? then
        puts "!!!!! !!!!! !!!! Element Not Visible !!!!! !!!!! !!!! " + name
        return false
    end

    if tag && !disabled && !readonly then

        selector = tag +"[name=\"" + name + "\"]"

        if tag == "INPUT" then

            tag = d.execute_script("return document.getElementsByName(\"" + name + "\")[0].type")
            puts "type = " + tag

            if tag == "radio" then

                radioButtonEx(d,selector,v)

            elsif tag == "checkbox" then

                checkBox(d,selector,v)

            elsif tag == "hidden" then

                p "hidden tag"

            else

                inputText(d,selector,v )

            end

        elsif tag == "SELECT" then

            selectOptionEx(d,selector,v)

        elsif tag == "TEXTAREA" then

            inputTextArea(d,selector,v)

        end

    end

    sleep 0.3

end

def md5(url)

	clnt = HTTPClient.new
	clnt.ssl_config.verify_mode = OpenSSL::SSL::VERIFY_NONE
	return Digest::MD5.hexdigest(clnt.get_content(url))

end

def termcheck(terms,md5s)

	for term in terms do

		if md5s.include?( md5(term) ) then
			next
		else
			puts md5(term)
			return false
		end
	end

	return true

end

##
## 指定要素が表示されるまでチェックを行う（文字列検索）
##------------------------------------------------------------------------------------------
def waitElementView(d, s, msg, beforeURL)

    $msg = "Processing [waitElementView] : " + msg
    $log.info($msg)

    begin

    	## 共通変数
    	$checkRetry = 10		# Wait Time 10sec
    	$timeOutFlg = true	# Time out Flug
    	$result = false			# Element exists

        for i in 1..$checkRetry

            ##-- 画面遷移後URL取得
            afterURL = d.current_url

            sleep 1
            $log.info(">> Check count " + i.to_s)

            ##-- URL比較
            $log.info(">> beforeURL " + beforeURL)
            $log.info(">> afterURL " + afterURL)
            if beforeURL != afterURL then

                ##-- 要素存在確認
                $log.info(">> Screen transition done.")
                element = d.execute_script("return document.querySelector('" + s + "')")
                unless !element then

                    # テキスト文字列存在確認
                    if d.find_element(:css, s).text.include?(msg) then
                        $timeOutFlg = false
                        $result = true
                        break
                    end

                end

            else

                # 画面遷移が完了していない
                $log.info(">> Screen transition not done.")

            end

        end

    rescue Selenium::WebDriver::Error::StaleElementReferenceError

    	puts "Selenium::WebDriver::Error::StaleElementReferenceError"
    	retry

    end

    ##-- タイムアウト判定
    if $result == false && $timeOutFlg == true then
        $log.info("> " + $checkRetry.to_s + " seconds elapsed, timeout.")
    end

    return $result

end

##
## サプライヤ側とjson_data（マッピング後）が一致しているかチェック
##------------------------------------------------------------------------------------------
def checkMatchValue(d, type, s, check_data, selector = "")

    ##-- サプライヤの入力データ取得
    if type === "id" then
        supplier_data = d.execute_script("return document.getElementById('" + s + "').value;")
    elsif type === "name" && selector === "radio_button"
        tmp_list = d.execute_script("supplier_list = []; cnt = 0; var elements = document.getElementsByName('" + s + "'); for(var i = 0 ; i < elements.length ; i ++){if(elements[i].checked){supplier_list[cnt] = elements[i].value; cnt++;}} return supplier_list;")
        supplier_data = tmp_list[0]
    elsif type === "name" && selector === ""
        supplier_data = d.execute_script("supplier_list = []; var elements = document.getElementsByName('" + s + "'); return elements[0].value;")
    elsif type === "class" && selector === ""
        supplier_data = d.execute_script("return document.querySelector('" + s + "').value;")
    end

  	##-- ログメッセージ
    msg = createRealTimeCheckLogMsg(supplier_data, check_data)

    ##-- サプライヤの入力データと比較
    if check_data === supplier_data then
        $log.info(msg + ":Match value.")
        return true
    else
        err_location = 	type + ":" + s
        err_time = Time.now.strftime("%Y-%m-%d %H:%M:%S")
        msg = msg + + " エラー発生箇所:" + err_location + " エラー発生時刻:" + err_time
        handlingErrRealTimeCheck(d, msg, supplier_data, check_data, err_location, err_time)
    end

end

##
## サプライヤ側とjson_data（マッピング後）が一致しているかチェック
##------------------------------------------------------------------------------------------
def checkMatchText(d, type, s, check_data, selector = "")

    ##-- サプライヤの入力データ取得
    if type === "id" then
        supplier_data = d.execute_script("return document.getElementById('" + s + "').innerHTML;")
    elsif type === "class" && selector === "" then
        supplier_data = d.execute_script("return document.querySelector('" + s + "').innerHTML;")
    elsif type === "name" then
        supplier_data = d.execute_script("supplier_list = []; var elements = document.getElementsByName('" + s + "'); return elements[0].innerHTML;")
    end

  	##-- ログメッセージ
    msg = createRealTimeCheckLogMsg(supplier_data, check_data)

    ##-- サプライヤの入力データと比較
    if check_data === supplier_data then
        $log.info(msg + ":Match value.")
        return true
    else
        err_location = 	type + ":" + s
        err_time = Time.now.strftime("%Y-%m-%d %H:%M:%S")
        msg = msg + + " エラー発生箇所:" + err_location + " エラー発生時刻:" + err_time
        handlingErrRealTimeCheck(d, msg, supplier_data, check_data, err_location, err_time)
    end

end

##
## サプライヤ側とjson_data（マッピング後）が一致しているかチェック（checkボックス用）
##------------------------------------------------------------------------------------------
def checkBoxMatchValue(d, type, s, check_list)

    ##-- サプライヤの入力データ取得
    if type === "name" then
        supplier_list = d.execute_script("supplier_list = []; cnt = 0; var elements = document.getElementsByName('" + s + "'); for(var i = 0 ; i < elements.length ; i ++){if(elements[i].checked){supplier_list[cnt] = elements[i].value; cnt++;}} return supplier_list;")
    end

		if supplier_list != nil then
	    supplier_list = supplier_list.sort
	    check_list = check_list.sort
		end

		##-- ログメッセージ
		msg = createRealTimeCheckLogMsg(supplier_list.to_s, check_list.to_s)

		if check_list == supplier_list then
			$log.info(msg + ":Match value.")
			return true
		else
			err_location = 	type + ":" + s
			err_time = Time.now.strftime("%Y-%m-%d %H:%M:%S")
			msg = msg + + " エラー発生箇所:" + err_location + " エラー発生時刻:" + err_time
			handlingErrRealTimeCheck(d, msg, supplier_list.to_s, check_list.to_s, err_location, err_time)
		end

end

##
## リアルタイムチェック用ログメッセージ生成
##------------------------------------------------------------------------------------------
def createRealTimeCheckLogMsg(get_data, input_data)

    msg = "SEQ_ID:" + $json_data['SEQ_ID'] + " AGENT_ID:" + $json_data['AGENT_ID'] + " 取得値:" + get_data + " 入力値:" + input_data
    return msg

end

##
## リアルタイムチェック用エラー処理
##------------------------------------------------------------------------------------------
def handlingErrRealTimeCheck(d, log_msg, get_data, input_data, err_location, err_time)

    ss(d,$dir)
    $SET_PROC_NAME = "Not match value."
    postJson($json_data['CALLBACKURL'], make_RealTimeCheckStatusCode("INFO", $json_data['SEQ_ID'], "411", $USER_ID, get_data, input_data, err_location, err_time, $SET_PROC_NAME))
    $log.info(log_msg + ":411:Not match value.")
    d.quit
    exit(99)

end

##
## リアルタイムチェック用エラー処理
##------------------------------------------------------------------------------------------
def handlingErrRealTimeCheck(d, log_msg, get_data, input_data, err_location, err_time)

    ss(d,$dir)
    $SET_PROC_NAME = "Not match value."
    postJson($json_data['CALLBACKURL'], make_RealTimeCheckStatusCode("INFO", $json_data['SEQ_ID'], "411", $USER_ID, get_data, input_data, err_location, err_time, $SET_PROC_NAME))
    $log.info(log_msg + ":411:Not match value.")
    d.quit
    exit(99)

end

##
## 0埋め数値の文字列を数値型に変換
##------------------------------------------------------------------------------------------
def convertInteger(formatInteger)

    if formatInteger[0, 1] == "0" then

        convertNum = formatInteger[1, 1].to_i

    else

        convertNum = formatInteger.to_i

    end

    return convertNum

end
