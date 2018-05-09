<?
##
## 自動申し込みステータス受け取り、DB反映API
##

##-- インクルード
require('inc/master.inc');

##
## Selenium ステータス取得
##
$jsonData = file_get_contents('php://input');
$jsonData = mb_convert_encoding($jsonData, 'UTF8', 'ASCII,JIS,UTF-8,EUC-JP,SJIS-WIN');
$r = json_decode($jsonData, TRUE);
if ($r === NULL) { return; }

##
## データ変換
##
# ステータスコード
if ($r['status'] == "201") { $STATUS = "201"; } // 201:登録処理中
if ($r['status'] == "210") { $STATUS = "1"; } // 1:登録済
if ($r['status'] == "211") { $STATUS = "1"; } // 1:登録済（例外処理）
if (mb_substr($r['status'], 0, 1) == "4") { $STATUS = "4"; } // 4:登録エラー
if (mb_substr($r['status'], 0, 1) == "5") { $STATUS = "5"; } // 5:既に登録済み

# ステータス変更
if ($STATUS === "201" || $STATUS === "1" || $STATUS === "4" || $STATUS === "5") {


        # ユーザID / エージェントID
        $seqid = explode("_", $r['seqid']);
        $USER_ID  = $seqid[0];
        $AGENT_ID   = $seqid[1];

        $data['USER_ID'] = $USER_ID;
        $data['AGENT_ID'] = $AGENT_ID;
        $data['AGENT_DATA_TYPE'] = "WEB";
        $data['STATUS'] = $STATUS;
        $data['DELETE_DATE'] = cDate::now();
        $data['LAST_UPDATE'] = cDate::now();
        $data['DEL_FLG'] = '';

        ##-- 申し込み処理中レコード取得
        $checkStatus = "";
        if ($STATUS === "201") {

            /*
            USER_ID = $USER_ID;
            AGENT_ID = $AGENT_ID;

            $result = array();
            $result = SELECT * FROM <TABLE_NAME> WHERE USER_ID = <USER_ID> AND AGENT_ID = <AGENT_ID> AND STATUS = '201';
            $checkStatus = (array)$result;
            */

        }

        ##-- 申し込み状況更新
        $cond = array();
        // USER_ID = $USER_ID;
        // AGENT_ID = $AGENT_ID;
        if (empty($checkStatus)) {

            /*
            UPDATE <TABLE_NAME> SET [$data] WHERE USER_ID = <USER_ID> AND AGENT_ID = <AGENT_ID> AND AGENT_DATA_TYPE = 'WEB';
            */

            if ($STATUS== "1" || $STATUS== "5") {

                /*
                $result = array();
                $result = SELECT * FROM <TABLE_NAME> WHERE AGENT_ID = <AGENT_ID>;
                $AgentData = (array)$result;
                */

                if (!empty($AgentData)) {

                    /*
                    AGENT_ID = $AgentData[0]['AGENT_ID'];
                    USER_ID = $USER_ID;
                    UPDATE <TABLE_NAME> SET [$data] WHERE USER_ID = <USER_ID> AND AGENT_ID = <AGENT_ID> AND AGENT_DATA_TYPE = 'WEB';
                    */

                }

            }
            if ($STATUS === "201") { return; }

        } else {

            // サプライヤ登録処理中 5分以上経過しているものはステータスを4に変更
            $data['STATUS'] = "4";
            /*
            UPDATE <TABLE_NAME> SET [$data] WHERE USER_ID = <USER_ID> AND AGENT_ID = <AGENT_ID> AND AGENT_DATA_TYPE = 'WEB' AND STATUS = '201' AND time_to_sec(TIMEDIFF(NOW(), LAST_UPDATE)) > '300';
            */

        }

        ##-- ユーザ登録情報取得
        /*
        $result = array();
        $result = SELECT * FROM <TABLE_NAME> WHERE USER_ID = <USER_ID>;
        $stepData = (array)$result;
        */

        ##-- サプライヤ登録完了処理
        if ($STATUS === "1") {

            #>> 登録完了メール送信処理等記述

        }

        ##-- サプライヤ登録エラーメール
        if ($STATUS === "4") {

            #>> 登録エラーメール送信処理等記述

        }

        ##-- サプライヤ登録済み通知メール
        if ($STATUS === "5") {

            #>> 登録済み通知メール送信処理等記述

        }

}

?>
