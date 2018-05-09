=begin
AEON
Version：2018/05/05
=end

# encoding: utf-8
require_relative '../lib/common.rb'
require "selenium-webdriver"
require 'active_support'
require 'logger'
require "json"
require "date"
require 'nkf'


##
##  JSONファイル有無判定
##
if __FILE__ == $0


        ##-- ロギング
        $log = Logger.new(Dir.pwd + "/log/proc_" + Time.now.strftime("%Y%m%d") + ".log")

        ##-- ディレクトリファイル有無判定
        $dir = ARGV[0]
        if ARGV[0] == nil then
            $log.error("ARGV[0] is empty")
            exit(99)
        end

        ##-- ロギング
        $log = ActiveSupport::Logger.new($dir + "/rb.log")
        $console = ActiveSupport::Logger.new(STDOUT)
        $log.formatter = ::Logger::Formatter.new
        $console.formatter = ::Logger::Formatter.new
        $log.extend ActiveSupport::Logger.broadcast($console)

        ##-- config.jsonファイル有無確認
        jsonfile = $dir + "/config.json"
        if !File.exist?(jsonfile) then
            $log.error("jsonfile not found " + jsonfile)
            exit(98)
        end

        ##-- config.jsonファイル取得
        $json_data = open(jsonfile) do |io|
            JSON.load(io)
        end


        ##
        ##  自動入力処理
        ##
        begin


            ##
            ##  初期処理
            ##

            ## ユーザIDセット
            $USER_ID = $json_data['USER_ID']

            ## サプライヤ登録処理中フラグセット
            postJson($json_data['CALLBACKURL'], make_StatusCode("INFO", $json_data['SEQ_ID'], "201", $USER_ID, "登録処理中"))
            $log.info($json_data['SEQ_ID'] + ":201:登録処理中")

            ## サイトURLセット
            base_url = "https://www.aeonet.co.jp/form/index.php?MODE=3"

            ##-- ブラウザ起動処理
            profile = Selenium::WebDriver::Firefox::Profile.new
            profile['intl.accept_languages'] = "ja"
            profile['general.useragent.locale'] = "ja-JP"
            profile['browser.popups.showPopupBlocker'] = false
            profile['dom.disable_beforeunload'] = true
            profile['network.dns.disableIPv6'] = true
            d = Selenium::WebDriver.for :firefox, :profile => profile
            d.manage.timeouts.implicit_wait = 5

            ##-- サイト表示
            d.get base_url

            ## MRデータ格納配列初期化
            $MR_DATA = Hash.new

            ##
            ##  Step1 入力画面
            ##===============================================================================================
            $log.info("Step1 入力画面： " + $json_data['SEQ_ID'])

            ## > 学習目的
            select = Selenium::WebDriver::Support::Select.new(d.find_element(:name, "learningpurpose"))
            select.select_by(:text, $json_data['PURPOSE'])

            ## > 氏名 姓
            set(d, 'lastname', $json_data['FAMILYNAME'])

            ## > 氏名 名
            set(d, 'firstname', $json_data['FIRSTNAME'])

            ## > フリガナ 姓
            set(d, 'yomilastname', $json_data['FAMILYNAMEKANA'])

            ## > フリガナ 名
            set(d, 'yomifirstname', $json_data['FIRSTNAMEKANA'])

            ## > 学習目的
            select = Selenium::WebDriver::Support::Select.new(d.find_element(:name, "jobage"))
            select.select_by(:text, $json_data['OCCUPATIONCTG'])

            ## > 性別
            if $json_data['GENDER'] == "1" then

                # 男性
                d.find_element(:css, 'div.form_item:nth-child(7) > div:nth-child(2) > span:nth-child(1) > label:nth-child(2)').click

            else

                # 女性
                d.find_element(:css, 'div.form_item:nth-child(7) > div:nth-child(2) > span:nth-child(2) > label:nth-child(2)').click

            end

            ## > 郵便番号
            set(d, 'zipcode1', $json_data['ZIPCODE3DGTS'])
            set(d, 'zipcode2', $json_data['ZIPCODE4DGTS'])

            ## > 都道府県
            select = Selenium::WebDriver::Support::Select.new(d.find_element(:name, "prefectures"))
            select.select_by(:text, $json_data['ADDRESS1'])

            ## > 市区町村

            $ADDRESS1 = $json_data['ADDRESS1'].to_s + $json_data['ADDRESS2'].to_s + $json_data['ADDRESS3'].to_s
            set(d, 'city', $ADDRESS1)

            ## > 番地
            address4 = $json_data['ADDRESS4'].to_s.empty? ? "" : NKF.nkf('-m0Z1 -w', $json_data['ADDRESS4'].to_s) + "丁目"
            address5 = $json_data['ADDRESS5'].to_s.empty? ? "" : NKF.nkf('-m0Z1 -w', $json_data['ADDRESS5'].to_s) + "番地"
            address6 = $json_data['ADDRESS6'].to_s.empty? ? "" : NKF.nkf('-m0Z1 -w', $json_data['ADDRESS6'].to_s) + "号"
            $ADDRESS2 = address4 + address5 + address6
            set(d, 'line2', $ADDRESS2)

            ## > マンション
            set(d, 'line3', $json_data['ADDRESS7'])

            ## > お電話番号（携帯固定）
            d.find_element(:css, 'div.form_item:nth-child(15) > div:nth-child(2) > span:nth-child(1) > label:nth-child(2)').click
            set(d, 'tel1', $json_data['MOBTELAREA'])
            set(d, 'tel2', $json_data['MOBTELLOCAL'])
            set(d, 'tel3', $json_data['MOBTELNUMBER'])

            ## > メールアドレス（パソコン固定）
            d.find_element(:css, 'div.form_itemBorder:nth-child(16) > div:nth-child(2) > span:nth-child(2) > label:nth-child(2)').click
            $EMAIL = $json_data['EMAILADDRPC'] + "@" + $json_data['EMAILADDRPCDOMAIN']
            set(d, 'mail', $EMAIL)

            ## > 資料ご希望コース
            select = Selenium::WebDriver::Support::Select.new(d.find_element(:name, "doccourcehead1"))
            select.select_by(:text, $json_data['COURCE_1'])
            select = Selenium::WebDriver::Support::Select.new(d.find_element(:name, "doccourcedetail1"))
            select.select_by(:text, $json_data['COURCE_DETAIL_1'])

            ## > お近くのイーオン
            select = Selenium::WebDriver::Support::Select.new(d.find_element(:name, "area"))
            select.select_by(:text, $json_data['AREA'])
            select = Selenium::WebDriver::Support::Select.new(d.find_element(:name, "school"))
            select.select_by(:text, $json_data['SCHOOL'])
            set(d, 'areatxt', $json_data['AREATXT'])

            ## > 「個人情報の取扱について」に同意する
            d.find_element(:css, ".checkbox").click

            ##-- スクリーンショット取得
            ss(d,$dir)

            ##-- URL取得
            beforeURL = d.current_url

            ##-- 同意して入力内容を確認する
            s = '.btn_orange'
            waitSubmitVisibleSelector(d,s)

            #//////////////////////////////////////
            # 入力バリデーションの判定処理等を記述
            #//////////////////////////////////////

            ##-- 画面遷移確認
            s = ".headTitle > div:nth-child(1) > h2:nth-child(1)"
            msg = "資料請求お申し込みフォーム"
            if !waitElementView(d, s, msg, beforeURL) then
                ss(d,$dir)
                $SET_PROC_NAME = "Screen transition to [Step2 確認画面] failed."
                postJson($json_data['CALLBACKURL'], make_StatusCode("ERROR", $json_data['SEQ_ID'], "405", "", $SET_PROC_NAME))
                $log.error($json_data['SEQ_ID'] + ":405:" + $SET_PROC_NAME)
                d.quit
                exit(1)
            end


            ##
            ##  Step2 確認画面
            ##===============================================================================================
            $log.info("Step2 確認画面： " + $json_data['SEQ_ID'])

            ##-- スクリーンショット取得
            ss(d,$dir)

            ##-- URL取得
            beforeURL = d.current_url


#//////////////////////////////////////
# サンプルの為、本登録処理は省く
#//////////////////////////////////////
=begin

            ##-- 登録
            s = '#comp'
            waitSubmitVisibleSelector(d,s)

            ##-- 画面遷移確認
            s = "<登録完了画面タイトルエレメントのCSSセレクター名>"
            msg = "<登録完了画面タイトル>"
            if !waitElementView(d, s, msg, beforeURL) then
                ss(d,$dir)
                $SET_PROC_NAME = "Screen transition to [Step3 完了画面] failed."
                postJson($json_data['CALLBACKURL'], make_StatusCode("ERROR", $json_data['SEQ_ID'], "405", "", $SET_PROC_NAME))
                $log.error($json_data['SEQ_ID'] + ":405:" + $SET_PROC_NAME)
                d.quit
                exit(1)
            end


            ##
            ##  Step3 完了画面
            ##===============================================================================================
            $log.info("Step3 完了画面： " + $json_data['SEQ_ID'])

            ##-- スクリーンショット取得
            ss(d,$dir)

=end


            ## 登録完了
            if $MR_DATA.empty? then

                postJson($json_data['CALLBACKURL'], make_StatusCode("INFO", $json_data['SEQ_ID'], "210", $USER_ID, "登録完了"))
                $log.info($json_data['SEQ_ID'] + ":210:" + $USER_ID + ":登録完了")

            else

                postJson($json_data['CALLBACKURL'], mr_make_StatusCode("INFO", $json_data['SEQ_ID'], "211", $USER_ID, $MR_DATA, "登録完了（完了処理例外用）"))
                $log.info($json_data['SEQ_ID'] + ":211:" + $USER_ID + ":登録完了（完了処理例外用）")

            end

            puts "登録完了画面前で強制終了"
            sleep 10
            d.quit


            ##
            ## エラー出力
            ##------------------------------------------------------------------------------------------
            rescue Selenium::WebDriver::Error::NoSuchElementError => e
                ss(d,$dir)
                $e_message = e.message.gsub(/"/, "")
                postJson($json_data['CALLBACKURL'], make_StatusCode("ERROR", $json_data['SEQ_ID'], "406", "", $e_message))
                puts e.message
                puts caller.first.scan(/`(.*)'/).to_s
                puts e.backtrace
                $log.error(e.backtrace)
                d.quit
                exit(10)

            rescue Selenium::WebDriver::Error::ElementNotVisibleError => e
                ss(d,$dir)
                $e_message = e.message.gsub(/"/, "")
                postJson($json_data['CALLBACKURL'], make_StatusCode("ERROR", $json_data['SEQ_ID'], "407", "", $e_message))
                puts e.message
                puts caller.first.scan(/`(.*)'/).to_s
                puts e.backtrace
                $log.error(e.backtrace)
                d.quit
                exit(11)

            rescue Selenium::WebDriver::Error::UnknownError => e
                ss(d,$dir)
                $e_message = e.message.gsub(/"/, "")
                postJson($json_data['CALLBACKURL'], make_StatusCode("INFO", $json_data['SEQ_ID'], "408", "", $e_message))
                puts e.message
                puts caller.first.scan(/`(.*)'/).to_s
                puts e.backtrace
                $log.error(e.backtrace)
                d.quit
                exit(12)

            rescue Selenium::WebDriver::Error::JavascriptError => e
                ss(d,$dir)
                $e_message = e.message.gsub(/"/, "")
                postJson($json_data['CALLBACKURL'], make_StatusCode("ERROR", $json_data['SEQ_ID'], "409", "", $e_message))
                puts e.message
                puts caller.first.scan(/`(.*)'/).to_s
                puts e.backtrace
                $log.error(e.backtrace)
                d.quit
                exit(13)

            rescue TypeError => e
                ss(d,$dir)
                $e_message = e.message.gsub(/"/, "")
                postJson($json_data['CALLBACKURL'], make_StatusCode("ERROR", $json_data['SEQ_ID'], "410", "", $e_message))
                puts e.message
                puts caller.first.scan(/`(.*)'/).to_s
                puts e.backtrace
                $log.error(e.backtrace)
                d.quit
                exit(14)

        end
        #-- ▲ 自動入力処理 --#

end
#-- ▲ JSONファイル有無判定 --#
