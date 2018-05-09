# SSL証明書用
ENV['SSL_CERT_FILE'] = File.expand_path('./cacert.pem',File.dirname(__FILE__))

require_relative './lib/common.rb'
require 'httpclient'
require 'net/http'
require 'net/https'
require 'open-uri'
require 'fileutils'
require 'inifile'
require 'logger'
require "open3"
require 'date'
require 'json'


##
## 実行プロセス判定
##
##-- Ruby プロセス取得
o, e, s = Open3.capture3('wmic process where "(name = "ruby.exe")" get CreationDate, Name, ProcessId /FORMAT:LIST')

##-- Ruby プロセス数カウント
$MAX_PROC = 2 # 最大同時実行数
$CURRENT_PROC = 0
$PROCS = o.split("\n")
$PROCS.each{|v|

	if v.include?("ProcessId") then
			r = v.split("=")
			$CURRENT_PROC += 1
	end

}
##-- Ruby プロセス数判定
if $CURRENT_PROC > $MAX_PROC then
	puts Time.now.strftime("%Y-%m-%d_%H_%M_%S") + "Info: Maximum number [" + $MAX_PROC.to_s + "] of executions reached."
	sleep 5
	exit(0)
end

##
## 初期設定（domain/url/url_callbackは環境に応じて変更）
##
##-- 処理インターバル（5秒）
interval = 5
sleep(interval)

##-- Firefox プロセスステータス取得
$PAST = 5 # 分
$pastTime = Time.now - (60 * $PAST)
$setPastTime = $pastTime.strftime("%Y%m%d%H%M%S")
o, e, s = Open3.capture3('wmic process where "(name = "firefox.exe" and CreationDate < "' + $setPastTime + '.0+540")" get CreationDate, Name, ProcessId /FORMAT:LIST')

##-- Firefox プロセス終了（$PAST以前のプロセスを強制終了）
$PROCS = o.split("\n")
$PROCS.each{|v|

		if v.include?("ProcessId") then
			r = v.split("=")
			system('taskkill /pid ' + r[1] + ' /F')
		end

}

##-- インスタンスID取得
begin

		configfile = IniFile.load('./balancing.conf')
		$INSTANCE = configfile['MR']['INSTANCE']
		$INSTANCE.empty?

rescue => e

		puts Time.now.strftime("%Y-%m-%d %H:%M:%S") + " [Error] could not read balancing.conf or instance key."
		sleep 5
		exit

end

##-- API HostIP or Domain
domain = "<HOST_NAME>"

##-- データ取得URL
url = 'http://' + domain + '/api/getData.php?instance_id=' + $INSTANCE # https

##-- ステータス返却URL
url_callback = 'http://' + domain + '/api/returnStatus.php'

##-- エージェント自動申し込みスクリプト保存場所
agentfile = File.join(File.dirname(__FILE__), "site")

##-- 自動申し込み処理
puts Time.now.strftime("%Y-%m-%d_%H_%M_%S")

##-- ロギング
$log = Logger.new(Dir.pwd + "/log/proc_" + Time.now.strftime("%Y%m%d") + ".log")

##-- データ取得
begin
		data = open(url)
rescue OpenURI::HTTPError => e

		puts e.message
		puts e.backtrace
		$log.error(e.message)
		$log.error(e.backtrace)
		sleep(interval)
		return

else

		##-- 取得データJSON変換
		json_data = JSON.load(data.read)

		# データ無
		if json_data['exists'] == false then
				puts "There is No Data. Continue processing..."
				exit
		end

		# 処理データ情報表示
		puts json_data['SEQ_ID']
		$log.info(json_data['SEQ_ID'])
		$log.info(data.status)
		$log.info(data.content_type)
		$log.info(data.meta)

end

##-- 申込情報保存ディレクトリ作成（./users/YYYY/MM/USER_ID）
Time.now.strftime("%Y-%m-%d_%H_%M_%S")
save_dir = File.join(File.dirname(__FILE__), "users", Time.now.strftime("%Y"), Time.now.strftime("%m"))
user_dir = File.join(save_dir, json_data['SEQ_ID'])
FileUtils.mkdir_p(user_dir)

# 申込情報保存ディレクトリ作成失敗
if !File.exist?(user_dir) then
		postJson(url_callback, make_StatusCode("ERROR", json_data['SEQ_ID'], "401", "", "申込情報保存ディレクトリ作成失敗"))
		$log.error(json_data['SEQ_ID'] + ":401:申込情報保存ディレクトリ作成失敗")
		exit
end

##-- 申込情報保存
user_file = File.join(save_dir, json_data['SEQ_ID'], "config.json")
open(user_file, 'w') do |io|
		JSON.dump(json_data, io)
end

# 申込情報ファイル作成失敗
if !File.exist?(user_file) then
		postJson(url_callback, make_StatusCode("ERROR", json_data['SEQ_ID'], "402", "", "申込情報ファイル作成失敗"))
		$log.error(json_data['SEQ_ID'] + ":402:申込情報ファイル作成失敗")
		exit
end

##-- エージェント自動申し込みスクリプト実行

# スクリプト取得
script = File.join(agentfile, json_data['AGENT_ID'] + ".rb" ) # ./agent/<AgentScript>.rb

# スクリプト取得失敗
if !File.exist?(script) then
		postJson(url_callback, make_StatusCode("ERROR", json_data['SEQ_ID'], "403", "", "エージェント自動申し込みスクリプトが存在しない"))
		$log.error(json_data['SEQ_ID'] + ":403:エージェント自動申し込みスクリプトが存在しない")
		exit
end

# スクリプト実行
cmd = sprintf("ruby %s %s", script, user_dir)
t = Thread.new(cmd) {

		system %Q|cmd /C "start #{cmd}"|;

}
t.join
