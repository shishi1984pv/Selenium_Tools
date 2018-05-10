# Selenium_Tools

## overview

特定サイトへの自動申し込みツール。
SampleではAEONの資料請求サイトにユーザ情報を入力し、登録完了前の画面まで遷移。

----
## environment

Windows端末に以下を事前にインストール。


◆Ruby（2.3.3p222）

`ruby --version
ruby 2.3.3p222 (2016-11-21 revision 56859) [x64-mingw32]`

`gem install selenium-webdriver -v "3.4.0"`

`gem install httpclient`

`gem install activesupport`

`gem install i18n`

`gem install inifile`

◆Selenium（Webdriver：3.4.0）

`C:\Ruby23-x64\lib\ruby\gems\2.3.0\gems`

◆Firefox（version 54.0）

[Download Firefox 54.0](https://www.mozilla.jp/firefox/54.0/releasenotes/)

>※カスタムインストール：Maintenance Serviceはインストールしない

>※自動更新無効化設定：オプション > 詳細 > 更新 > 更新の確認は行わない

◆GeckoDriver（version 0.18.0）

[Download GeckoDriver 0.18.0](https://github.com/mozilla/geckodriver/releases/tag/v0.18.0)

> Version：geckodriver-v0.18.0-win64.zip

> Entity：geckodriver.exe

> Install：Entityを「C:\Ruby23-x64\bin」へ移動

`CLI：geckodriver --version`


----
## usage

1. 「api」をWebサーバに配備（http://<HOST_NAME>/api/getData.phpにアクセス可能にする）
2. 「local」をWindows端末にダウンロード

3. `MultiProc.rb`の<HOST_NAME>に、上記のWebサーバのIPまたはDOMAINを設定

4. 以下のコマンドを実行

>
    C:\local> ruby MultiProc.rb

> ※`MultiProc.bat`はマルチスレッド用であるが、Sampleでは固有データを取得する為、`S0001.rb`をループ実行する事になる。
