<?
##
## 登録データ取得
##
/*
[STATUS]
ユーザの基本情報を取得済み 200
サプライヤへの登録処理中（Seleniumを実行中の状態）201
*/

##-- 実行インスタンス
$MR_INSTANCE = array(
    "MR_PROC_001",
    "MR_PROC_002"
);

##-- インスタンス判定
$INSTANCE = $_GET['instance_id'];
if(!in_array($INSTANCE, $MR_INSTANCE)) {
		echo "No Instance"; return;
}

##-- 初期設定
$HOST_NAME = "http://" . $_SERVER["HTTP_HOST"];
$CALLBACKURL = $HOST_NAME . "/api/returnStatus.php";

##-- 登録データ取得
##
## DBから登録フォーム入力用のデータを取得（申し込みSTATUSが"200"または"201"のレコードのみを取得）
## ここでは取得後のデータを成型した形で記述
##
$d['USER_ID'] = "1005432";
$d['AGENT_ID'] = "S0001";
$d['PURPOSE'] = "日常会話";
$d['FAMILYNAME'] = "原田";
$d['FIRSTNAME'] = "賢治";
$d['FAMILYNAMEKANA'] = "ハラダ";
$d['FIRSTNAMEKANA'] = "ケンジ";
$d['OCCUPATIONCTG'] = "会社員";
$d['GENDER'] = "1";
$d['ZIPCODE3DGTS'] = "101";
$d['ZIPCODE4DGTS'] = "0061";
$d['ADDRESS1'] = "東京都";
$d['ADDRESS2'] = "千代田区";
$d['ADDRESS3'] = "三崎町";
$d['ADDRESS4'] = "1";
$d['ADDRESS5'] = "9";
$d['ADDRESS6'] = "";
$d['ADDRESS7'] = "グリーンハイツ2305";
$d['TELAREA'] = "03";
$d['TELLOCAL'] = "6270";
$d['TELNUMBER'] = "1067";
$d['EXTENTION'] = "";
$d['MOBTELAREA'] = "080";
$d['MOBTELLOCAL'] = "4323";
$d['MOBTELNUMBER'] = "8334";
$d['EMAILADDRPC'] = "exsample";
$d['EMAILADDRPCDOMAIN'] = "gmail.com";
$d['EMAILADDRMOBILE'] = "";
$d['EMAILADDRMOBILEDOMAIN'] = "";
$d['COURCE_1'] = "日常英会話";
$d['COURCE_DETAIL_1'] = "教養として身につけたい";
$d['AREA'] = "東京都";
$d['SCHOOL'] = "＜山手線内＞神田校";
$d['AREATXT'] = "銀座線";
$d['INSTANCE_ID'] = "MR_PROC_001";
$d['CALLBACKURL'] = $CALLBACKURL;
$d['SEQ_ID'] = $d['USER_ID'] . "_" . $d['AGENT_ID'];

echo json_encode($d);
?>
