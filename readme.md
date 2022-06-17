![全景](./doc/全景.png)

# <span style="color:#ffff00">事前準備 RasPi Wifi設定</span>

## <span style="color:#DD8800; ">（RaspberryPi）Wifi設定の手順 ※既に行っている場合は飛ばしても良い</span>

[※参考リンク（同GitのWiFi設定手順ページ）](https://github.com/ksaplabo-org/Raspi-Setup#wifi%E8%A8%AD%E5%AE%9A%E3%81%AE%E6%89%8B%E9%A0%86)

OSインストールしたmicroSDのルートディレクトリダ配下に「ssh」という空のファイルを作成後、同階層に「wpa_supplicant.conf」というファイルを作成

その後、「wpa_supplicant.conf」ファイル内に以下のように書き込んで設定は完了
``` 
ctrl_interface=DIR=/var/run/wpa_supplicant GROUP=netdev
update_config=1
country=JP

network={
        ssid="1つ目のSSID"
        psk="1つ目のSSIDのパスワード"
        key_mgmt=WPA-PSK
}
```

# <span style="color:#ffff00">事前準備２ 研修用資材設置</span>
## <span style="color:#DD8800; ">研修で使用する下記資材を当日までにRaspberryPiに設置する</span>
設置場所は下記
```
home/pi/kensyu_aws_20220618
```
※「_yyyymmdd」部分に、研修当日の日付を入れる<br><br>

|格納フォルダ|格納資材|備考|
|:--|:--|:--|
|home/pi/kensyu_aws_20220618/kensyu_mqtt|[aircond2.py](./aircond2.py)|MQTT体験用|
|home/pi/kensyu_aws_20220618/kensyu_mqtt|[aircond3.py](./aircond3.py)|追加課題体験用|
<br>

***
★研修に使用するラズパイのDownloadsフォルダに何も入っていないことを確認する。余計なファイルは削除しておく
***
<br>


# <span style="color:#22AAFF">センサで温湿度を計測し、AWSにデータを通知する</span>

## <span style="color:#DD8800; ">（RaspberryPi）温度・湿度センサー環境の作成</span>

最初に、RaspberryPiに作業フォルダを作成する。
``` bash
$ mkdir AirCondition
$ cd AirCondition
```

下図のようにRaspberryPiと温湿度センサ「DHT11」を接続する。<br>
※全国研修では接続済のRaspberryPiを札幌支店に設置しておく

![DHT11](./doc/DHT11.png)

★上記図は修正予定<br><br>
GitHubからDHT11のライブラリを取得する。
``` bash
$ sudo git clone https://github.com/szazo/DHT11_Python.git
```

サンプル起動し、以下のように表示されれば接続はOK。

``` bash
$ sudo python3 ./DHT11_Python/example.py

Last valid input: 2021-11-03 22:44:57.427497
Temperature: 21.0 C
Humidity: 84.0 %
Last valid input: 2021-11-03 22:45:03.511665
Temperature: 22.0 C
Humidity: 73.0 %
：
```

***
★ここでexample.pyのプログラムの説明を行う
***

ライブラリ以外を削除する

``` bash
# gitファイル削除
$ cd DHT11_Python
$ rm -rf .git

# ライブラリ本体のフォルダをひとつ上に移動
$ cd ..
$ sudo mv -f ./DHT11_Python/dht11/ ./dht11

# 不要フォルダ削除
$ sudo rm -rf ./DHT11_Python
```

## <span style="color:#DD8800; ">（AWS）IoT Coreで「モノ」情報を作成</span>
※注意※　以下の作業からAWSでの作業が関わってくるが、右上の作業領域がデフォルトだと<br>
バージニア北部になっているため、<b>アジアパシフィック(東京)</b>に変更しておくこと。
<br>

以下の手順で、接続してくるRaspberryPiを、仮想の「モノ」として登録する 
- 「サービス」から「AWS IoT Core」を選択。
- 「管理」から「すべてのデバイス」→「モノ」(Thing)を選択し、「モノを作成」をクリック
- 「１つのモノを作成」を選んで「次へ」
- 「モノの名前」に任意の名前を入力（「air-condition-pi」）して「次へ」
- 「デバイス証明書」で「新しい証明書を自動生成 (推奨)」を選択して「次へ」
- 「証明書にポリシーをアタッチ」で「ポリシーを作成」をクリック。新たに開かれたタブにて以下の内容を入力して「作成」をクリック。
  - 名前：air-condition-pi-policy　（任意に設定できるが、今回はこの名前とする）
  - 効果：「許可」
  - アクション：「*」（選択）
  - リソースARN：「*」（入力）<br>
※ポリシー作成後(「ポリシー○○が正常に作成されました」表示後)はタブは閉じてよい。

- 「証明書にポリシーをアタッチ」に戻り、作成したポリシーを選択して「モノを作成」をクリック。
- ここで表示される証明書、プライベートキー、パブリックキーをすべてダウンロードする。<br>
※ここでダウンロード失敗した場合はポリシー作成からやり直し

また、RaspberryPiが接続するための、IoTエンドポイントを以下の手順で確認する。
- （AWS IoTメニューの）「設定」をクリック
- 「デバイスデータエンドポイント」にある「エンドポイント」をメモする。
***
【リモート研修時】<br>
★ダウンロードした証明書などのファイル類を、Teamsのチャット欄にアップロードしてもらう<br>
★アップロードされたファイルを、講師側で札幌支店ラズパイのDownloadsフォルダに格納する<br>
★エンドポイントもTeamsのチャット欄に貼ってもらう（モブプロドライバ交代時に引き継ぐため）
***

## <span style="color:#DD8800; ">（RaspberryPi）MQTT配信機能の体験</span>

MQTT動作確認用ソースを「AirCondition」フォルダにコピーする。

/home/pi/AirConditionにいることの確認
```
$ pwd
```
ファイルコピー
```
$ cp ../kensyu_aws_20220618/aircond2.py ./aircond2.py
```
MQTTクライアントのライブラリをインストールする。
``` bash
$ pip3 install paho-mqtt python-etcd
```


「AirCondition」フォルダにコピーしたaircond2.pyに下記修正を行う。
- ソース上の定義部分「# Mqtt Define」の内容を、前述のダウンロード・共有した証明書・エンドポイントに置き換える。
  - AWSIoT_ENDPOINT
  - MQTT_CERT
  - MQTT_PRIKEY

---- 
#### ここでのハマりどころ
- 注意点として、<span style="color:#FF4400">**取得した証明書や秘密鍵を作業フォルダにコピーしないこと。**</span>  
  `「$ git add .」`でうっかりGitHubにアップされてしまうリスクがある。  
  これらがVSSに上がると、GitHubとAWSの双方からセキュリティリスクの通知メールと、  
  アカウント停止警告メールが来ることになり、対応が大変。
----
<br>

## <span style="color:#DD8800; ">（AWS）IoT Coreで計測した温湿度データを受け取る</span>

以下の手順でRaspberryPiから配信された温湿度データを受信（サブスクライブ）する。
- 「サービス」から「AWS IoT Core」を選択。
- 「テスト」>「MQTTテストクライアント」を選択する。
- 「トピックをサブスクライブする」の「トピックのフィルター」に「topicAirCondition」と入力して、「サブスクライブ」を押す。
- 画面に、一定周期で以下のように表示されれば、受信OK。
``` bash
topicAirCondition
November 01, 2021, 22:23:12 (UTC+0900)
{
  "GetDateTime": "2021-11-01 22:23:09",
  "Temperature": 19.8,
  "Humidity": 70
}
：
```

## <span style="color:#DD8800; ">（AWS）受信したデータをDynamoDBに登録する

以下の手順でIoT Coreが受信したセンサデータを、DynamoDBに登録する。
- 「サービス」から「AWS IoT Core」を選択。
- 「メッセージのルーティング」（旧コンソールなら「ACT]）>「ルール」を指定して、以下の流れでルールを追加する。
  - 「ルールの作成」をクリック
  - ルール名を入力（「air_condition_entry_rule」）
  - ルールクエリステートメントに、以下の内容を設定。  
    `「SELECT GetDateTime,Temperature,Humidity FROM 'topicAirCondition'」`
  - アクションに「DynamoDBv2（DynamoDBテーブルの複数列にメッセージを分割する。）」を選択。
  - 「テーブルを作成」をクリックし、新しいリソースとして、DynamoDBに任意のテーブルを作成する。
    - DynamoDBテーブル作成画面のタブが開かれるので、テーブル名を入力する（「air-condition-data」）
    - パーティションキーは「GetDateTime」とする
    - 「テーブルの作成」ボタンをクリックする。
    - 「テーブルは正常に作成されました」という表示を確認したら、DynamoDBのタブを閉じる
  - IoTCoreのタブに戻り、DynamoDBのテーブル名選択部分の隣の更新ボタンをクリックする
  - 先ほど作成したテーブルが選択できるようになっているので、選択する
  - ロールの作成は任意。（<span style="color:#FF4400;">「DynamoDB:PutItem」ポリシーを持つロールが選択</span>されていれば良い）
  - ロール作成語は、画面下部の「次へ」「作成」を順にクリック
***
【リモート研修時】<br>
- 「新しいロールを作成する」をクリックする
- モーダル画面が表示されるので、ロール名を入力し、作成（「air-condition-role」）
- 「表示」をクリックする。IAMのロール設定画面が表示されるので「アクセス許可を追加」を選択し、「ポリシーをアタッチ」を選択
- 「その他の許可ポリシー」の検索窓に「DynamoDB」と入力
- 「 `AmazonDynamoDBFullAccess`」をチェック
- 「ポリシーをアタッチ」をクリック
- 「ポリシーがロールに正常にアタッチされました」が表示されたらOK。IAMのタブを閉じる

***
aircond2.pyを実行する

DynamoDBの画面を開き、「テーブル」>「項目の表示」をクリックして、センサから受信したデータが登録されていることを確認する。<br>
画面が更新されていないこともあるので、何度か画面更新も試す。

----
#### ここでのハマりどころ
- 「ルールクエリステートメント」欄には、初期表示で、サンプルとして`「SELECT * FROM 'iot/topic'」`と書かれている。  
  このサンプルでは、トピック名が（iot/を含む）「iot/topic」ということに注意。  
  パブリッシャ（RaspberryPi）側でトピック名に「iot/」を含めなかった場合は、ここも「~ FROM 'topicAirCondition'」というように、「iot/」は含める必要はない。
- DynamoDBにデータが登録されない場合は、以下の点をチェックすること。
  - （AWS IoT Coreメニューの）「テスト」>「MQTTテストクライアント」を開き、トピックにクエリステートメントのFROM句に書いた内容を入れ、データがサブスクライブ（受信）できること。
  - 「ルール」を編集し、「エラーアクション」としてエラー結果をS3に格納するようにアクションを追加して、再度RaspberryPiからの受信を受ける。S3にログが格納されればその内容を基に対応を行う。
----
<br>

# <span style="color:#22AAFF">DynamoDBへの登録をトリガして、Lineに通知を出す</span>

## <span style="color:#DD8800; ">（LINE Developers）LINEに通知先のチャネルを登録する
[LINE Developers](https://developers.line.biz/ja/)にアクセスし、以下の手順でチャネルを作成する。
- 画面右上から、LINEアカウントでログインする。
***
【リモート研修時】<br>
★アイコンとgmail.comが晒されるのことを伝え、勇気ある代表者を募る<br>
★絶対立候補してほしかったら事前に話しとおしておく
***
- 画面右下で「日本語」を選択。
- メニュー「プロバイダ」>「作成」ボタンをクリック
  - 「プロバイダ名」に任意の名前を設定（「airCondition」）
  - 「Message API」を選択（真ん中あたりにあるはず）
  - 必須項目を登録して、「作成」ボタンをクリック（内容は任意）
    - チャネル名「お部屋の空調さん」
    - チャネル説明「お部屋の状態をお知らせします。」
    - 大業種「電気・ガス・エネルギー」
    - 小業種「ガス」
- 作成したプロバイダを選択する。Messaging API設定タブを選択する。
  - 表示されるQRコードを、スマホカメラで読み取ると、スマホのLINEに通知チャネルが登録される。
  - 一番下にある「チャネルアクセストークン」の発行ボタンをクリック
  - コピーして、控える（通知先として、この後のlambdaに必要）
- Visual Studio Codeを起動して、LINEからピンポンがくるか、動作テスト。
***
【リモート研修時】<br>
★上記を行うには、用意してもらうPCにまたはリモート環境上にVSCODEが入っている必要あり
***
VSCODEにREST Clientをインストールしてもらう<br>
新規作成（新しいテキストファイル）→下記の内容を書き込み、Ctrl+Alt+RでPOSTして動作確認
``` json
POST https://api.line.me/v2/bot/message/broadcast
Authorization: Bearer [チャネルアクセストークン]
Content-Type : application/json 

{
    "messages": [
        {
            "type": "text",
            "text": "Hello World!"
        }
    ]
}
```
![LINE通知](./doc/LINENotified.png)


## <span style="color:#DD8800; ">（RaspberryPi）AWS Lambda用のファンクションを作成する

作業用のフォルダを作成する。<br>
/home/pi/AirConditionにいることの確認
``` bash
$ pwd
```
```
$ mkdir aws_lambda
$ cd aws_lambda

$ mkdir airConditionNotifyLineFunc
$ cd airConditionNotifyLineFunc
```
直下に、pythonソースファイル [lambda_function.py](./aws_lambda/airConditionNotifyLineFunc/lambda_function.py) を設置する（教材フォルダからlambda_function.pyをコピーする）

```
$ cp ../../../kensyu_aws_20220618/aws_lambda/airConditionNotifyLineFunc/lambda_function.py ./lambda_function.py
```
***
※ソースコード中の "access_token" は、後ほどlambda上で環境変数として設定する。<br>
※ソースコードのコメントアウト部分は、追加課題で使用する二酸化炭素センサ用の記述のためいったん無視する。

このソースファイルに必要なライブラリ「requests」を、カレントディレクトリ上にインストールする。
``` bash
$ pip install requests -t ./
```

ソース＋ライブラリをlambdaへのアップロード用にzip圧縮する。
``` bash
# カレントディレクトリにlambda_function.pyと各種ライブラリがあることを確認
$ ls 
  bin                                 idna-3.3.dist-info
  certifi                             lambda_function.py
  certifi-2021.10.8.dist-info         requests
  charset_normalizer                  requests-2.26.0.dist-info
  charset_normalizer-2.0.7.dist-info  urllib3
  idna                                urllib3-1.26.7.dist-info

$ zip -r airConditionNotifyLineFunc.zip ./*
```

## <span style="color:#DD8800; ">（AWS）LINE通知用のLambda関数を作成する

以下の手順でlambda関数を作成する
- 「サービス」から「Lambda」を選択。
- 「関数」>「関数の作成」画面で、以下を指定して「関数の作成」をクリックする。
  - 関数名：「airConditionNotifyLineFunc」。名称自体は任意だが、前の手順でzip作成した際の、フォルダ名とあわせる
  - ランタイム：Python 3.9
  - アーキテクチャ：x86_64
  - アクセス権限>デフォルトの実行ロールの変更：
    - 「基本的な Lambda アクセス権限で新しいロールを作成」を選択
- 「コード」タブ開く
  - 画面右上の「アップロード元」に「.zip」ファイルを選択する。前の手順で作成したzipファイルを指定して、ソースをアップロードする。
- 「設定」タブ>「アクセス権限」を開く
  - 「実行ロール」に表示されたロール名のリンクをクリック（IAMのロール画面に遷移する）
  - 「ポリシーをアタッチします」をクリックして、次のポリシーを追加
    - `AmazonDynamoDBFullAccess`
- 「設定」タブ>「環境変数」で「編集」ボタンを押して以下の環境変数を追加
  - 「access_token」：LINE Developers画面で控えた、チャネルアクセストークンを設定する。

動作確認。
- 「コード」タブ>「テスト」で、「テスト」ボタンに以下の内容を登録して、テスト実行する。
``` json 
{
    "Records": [
        {
            "dynamodb": {
                "NewImage": {
                    "GetDateTime": {
                        "S": "2021-11-03 16:20:18"
                    },
                    "Temperature": {
                        "N": "20.5"
                    },
                    "Humidity": {
                        "N": "72.3"
                    }
                }
            }
        }
    ]
}
```
実行して、LINEからピンポンがくるか、テストを行う 

![LINE通知](./doc/LINENotified2.png)

<br>

正常にLINEへの通知が来ることを確認できたら、以下の手順でDynamoDBテーブルの変更通知とつなげる。

- 「設定」タブ>「トリガー」で「トリガーを追加」ボタンをクリック
  - 「トリガーの設定」で「DynamoDB」を選択。
    - DynamoDBテーブル：「air-condition」
    - トリガーの有効化：チェック

<br>

トリガーが設定されると、上のLINE通知が1分に1回通知されてくるようになる。

![LINE通知](./doc/LINENotified3.png)

----
#### ここでのハマりどころ
- zip圧縮は、親フォルダを含めず、フォルダの内容だけを圧縮すること。
- 実行Pythonのソースファイル名は「lambda_function.py」とすること。これ以外に変更する場合は、（試していないが）ランタイム設定にあるハンドラ名を変更する必要がありそう。
- lambdaのevent引数に渡されてくるデータ構造がわらかなかった。これは、[こちらのドキュメント](https://docs.aws.amazon.com/ja_jp/lambda/latest/dg/with-ddb.html)か、テストデータ作成画面で表示されるテンプレートを参考にするとよい。
- lambdaが正しく機能しているかは、Cloud Watchログから確認する。ステータスコードが200ではなく429が返っているようであれば、これ ↓ が原因。
- <u><b>LINEへの通知リクエストが多発しないよう注意。</b></u>
  - [レート制限](https://developers.line.biz/ja/reference/messaging-api/#rate-limits)：60リクエスト/時
  
  - [その月の配信可能なメッセージ数の上限](https://www.linebiz.com/jp/manual/OfficialAccountManager/account-settings/)：フリープラン 1,000通/月

  - [開発ガイドライン](https://developers.line.biz/ja/docs/messaging-api/development-guidelines/)：「いかなる目的でも、同一ユーザーへメッセージを大量送信しないでください。」  

  基本的に多くても1分に1回を上限とするのがよさそう。上記いずれかに抵触すると、HTTPステータスコード「429」応答が返るようになる。そうでなくても、開発ガイドラインの記載違反なので、いつBANされるか…。
----
<br>

# <span style="color:#22AAFF">ElasticSearch+Kibanaでセンサーデータをグラフに可視化する</span>

## <span style="color:#DD8800; ">（AWS）VPCネットワークとEC2環境を構築する

![AWSNetWork](./doc/awsvpc.png)

独立したVPN一つと、publicサブネットを一つ作成し、上にEC2を構築する。  

  |種別|名前|IPアドレス|  
  |--|--|--|  
  |VPC|biweb-dev-vpc|11.0.0.0/16|  
  |サブネット|biweb-dev-pub-subnet1|11.0.16.0/20|  
  |EC2|biweb-dev-web|11.0.20.any|  

### 以下の手順で<b>VPC</b>を作成する
- 「サービス」から「VPC」を選択。
- サイドメニュー「VPC」>右側の画面で「VPCの作成」を選択し、遷移後の画面で、以下を指定して「VPCの作成」をクリックする。
  - 「作成するリソース」：VPC のみ ※VPCとサブネット類を同時に作成することもできるが、今回はVPC→サブネットの順に作成する
  - 「名前タグ - オプション」：上記表に記載している種別「VPC」に記載の名前を記入する
  - 「IPv4 CIDR ブロック」：上記表に記載している種別「VPC」に記載のIPアドレスを記入する
  - 「IPv6 CIDR ブロック」：IPv6 CIDR ブロックなし
  - タグ：特に設定しない（上記で設定したVPC名だけ設定されている状態でよい）

### 以下の手順で<b>サブネット</b>を作成する。
- 「サービス」から「VPC」を選択。
- サイドメニュー「サブネット」>右側の画面で「サブネットを作成」を選択し、遷移後の画面で、以下を指定して「サブネットを作成」をクリックする。
  - 「VPC」：上記手順で作成した「VPC」を選択
  - 「サブネット名」：上記表に記載している種別「サブネット」に記載の名前を記入する
  - 「アベイラビリティーゾーン」：アジアパシフィック (東京)ap-northeast-1a
  - 「IPv4 CIDR ブロック」：上記表に記載している種別「サブネット」に記載のIPアドレスを記入する
  - タグ：特に設定しない（上記で設定したVPC名だけ設定されている状態でよい）
  - 作成後、作成したサブネットを選択後、アクション>「サブネットの設定の編集」を開きIP アドレスの自動割り当て設定（チェックを入れる）
### 以下の手順で<b>EC2</b>を作成する。
- 「サービス」から「EC2」を選択。
- サイドメニュー「インスタンス」>右側の画面で「インスタンスを起動」を選択し、遷移後の画面で、以下を指定して「インスタンスを起動」をクリックする。
  - 「名前とタグ」：上記表に記載している種別「EC2」に記載の名前を記入する
  - 「Amazon マシンイメージ (AMI)」：Amanzon Linux 2 AMI (HVM) - Kernel 5
  - 「アーキテクチャ」：64ビット(x86)
  - 「インスタンスタイプ」：t3 large
  - 新しいキーペアの作成をクリック、アクセス用のキーペアをダウンロードして（というかされる）保存しておく
  - 「ネットワーク設定」の「編集」をクリック
    - 上記で作成したVPC,サブネットを選択する
    - ぱうりっくの自動割り当てはONにする
    - インバウンドのセキュリティグループには任意の名前と説明を設定する。セキュリティグループルールでは、SSHアクセスだけを許可とする。
    - ソースタイプ（Source）は「自宅のIP（マイIP）」をクリックして自宅のIPからの要求だけ許可とすー
  - タグ：特に設定しない（上記で設定したVPC名だけ設定されている状態でよい）
- EC2作成後、パブリックIPv4アドレスが割当されていることを確認する。

他、EC2作成以降の注意事項など。
- /16は先頭16ビットまでがサブネットマスクであることを示している（CIDR形式と呼ぶ）

<br>
自PCからのSSHアクセス

- VPCメニューから、インターネットゲートウェイ選択する
- 画面に従って「biweb-dev-igw」作成
- 画面に促されるまま作成したVPCにアタッチする
- VPCメニューから、サブネットを選択
- 先ほど作成したサブネット（biweb-dev-pub-subnet1）の左側にチェックを入れると画面下に「詳細」が出る
- 真ん中あたりにあるルートテーブルをクリックする
- ルートテーブルの編集画面に遷移するので画面下部の「ルートを編集」をクリック
- 下記を追加　（インターネットゲートウェイってのを選択すると作成したigwを選択できるようになるので設定）
  |送信先|ターゲット|
  |--|--|
  |0.0.0.0/0|（作成したIGW）|
***
【リモート研修】
SSMを利用した接続になるので、下記のteratermの説明は飛ばす

リモート注意点
- META端末にてログインする
- EC2サービスを開き、作成したEC2のIDをクリックし、開いた画面上部の「接続」をクリック
- SSHクライアントを選択し、下部にあるSSHコマンドをコピー
- 踏み台サーバーのダウンロードフォルダに入っているだろうprmをec2-userフォルダに移動させておく
- sudo をつけてsshコマンド実行
***
- ローカルPCで「Tera Term」を起動して、「Host」に作成したEC2のパブリックIPv4アドレスを指定する。  
  ![teraterm1](./doc/teraterm1.png)

- OK押下後の認証画面で、以下の内容を設定してOKをクリック。
   - 「User name」に「ec2-user」（これは固定値）
   - 「Use RSA/~(略)～ key to log in [Private key file:]」に、ダウンロードしたキーを選択  
  ![teraterm2](./doc/teraterm2.png)

- 以下のとおり、ログインが成功すれば、準備OK。

  ![teraterm3](./doc/teraterm3.png)
***
<br><br>
Amazon Linux2 EC2は、システム時間がGMTとなっており、日本時間と9時間のずれがある。  
[ここ](https://docs.aws.amazon.com/ja_jp/AWSEC2/latest/UserGuide/set-time.html#change_time_zone)を参考に、システム時間を日本標準時に設定する。

その後、必要最低限のソフトをインストールして環境を準備する

``` bash
# yumリポジトリ更新
$ sudo yum update -y

# java8 OpenJDK
$ sudo yum install java-1.8.0-openjdk.x86_64
```

## <span style="color:#DD8800; ">（AWS）EC2にElasticSearchをセットアップする

[公式サイト](https://www.elastic.co/guide/en/elasticsearch/reference/current/rpm.html)を参照しつつ、RPMを使用してインストールを行う。

GPG-KEYをローカルリポジトリにインポートする  　※GPGの説明は[こちら](https://qiita.com/y518gaku/items/435838097c700bbe6d1b#gpg%E3%81%A8%E3%81%AF)を参照
```
$ sudo rpm --import https://artifacts.elastic.co/GPG-KEY-elasticsearch
```

ElasticSearch RPMのrepoを所定フォルダに生成する
``` bash
$ sudo nano /etc/yum.repos.d/elasticsearch.repo
```

elasticsearch.repo への記載内容は以下の通り。
``` bash
[elasticsearch]
name=Elasticsearch repository for 7.x packages
baseurl=https://artifacts.elastic.co/packages/7.x/yum
gpgcheck=1
gpgkey=https://artifacts.elastic.co/GPG-KEY-elasticsearch
enabled=0
autorefresh=1
type=rpm-md
```

インストールコマンドを実行する
``` bash
$ sudo yum install --enablerepo=elasticsearch elasticsearch
：
：
Installed:
  elasticsearch.x86_64 0:7.15.1-1

Complete!
```

外部アドレスからのアクセスを可能にするため、設定ファイル「elasticsearch.yml」を開く。
```
$ sudo nano /etc/elasticsearch/elasticsearch.yml  
```

以下の箇所に追記を修正して、ファイルを保存。
```
# By default Elasticsearch is only accessible on localhost. Set a different
# address here to expose this node on the network:
#
#network.host: 192.168.0.1
network.host: 0.0.0.0   # ←ここを追記
discovery.type: single-node # ←ここを追記
```

また、同じファイルに対して最後の行に次の内容を設定しておく。
```
xpack.security.enabled: false  # ←ここを追記
```
上の意図は「セキュリティ機能を使用しない」というもの。  
今回はあえて使用しない。このように明示的に設定しないと、Kibana操作時に警告が多発する

↓ 警告表示の例（うざい）  

![elastic security err](./doc/elasticsecerr.png)


システム起動時にElasticSearchを起動するようにする（systemd）
``` bash
$ sudo /bin/systemctl daemon-reload
$ sudo /bin/systemctl enable elasticsearch.service

$ # （ちなみに、システムを 起動をやめさせたい場合は次のとおり）
$ sudo /bin/systemctl disable elasticsearch.service

```

以下、動作確認。まずはPCを再起動。
``` bash
$ sudo shutdown -r now
```

再起動後、起動状態をチェックする

``` bash
$ sudo systemctl | grep elastic
elasticsearch.service         loaded active running   Elasticsearch
```

以下のコマンドでサービス自体の起動を確認（デフォルトポートは 9200）
``` bash
$ sudo curl http://localhost:9200
{
  "name" : "ip-10-0-23-98.ap-northeast-1.compute.internal",
  "cluster_name" : "elasticsearch",
  "cluster_uuid" : "9RtovLuBTuyvlNjuMLLekg",
  "version" : {
    "number" : "7.15.1",
    "build_flavor" : "default",
    "build_type" : "rpm",
    "build_hash" : "83c34f456ae29d60e94d886e455e6a3409bba9ed",
    "build_date" : "2021-10-07T21:56:19.031608185Z",
    "build_snapshot" : false,
    "lucene_version" : "8.9.0",
    "minimum_wire_compatibility_version" : "6.8.0",
    "minimum_index_compatibility_version" : "6.0.0-beta1"
  },
  "tagline" : "You Know, for Search"
}
```

同様に外部からのアクセスを確認。最初にAWSのセキュリティグループで、ポート9200を許可設定する。
- VPC>作成したセキュリティグループを選択、「インバウンドのルールを編集」
- カスタムTCPで　9200ポートでインスタンス「に」アクセスできるようにするから「インバウンド」なんじゃ
- 
- 
![- awsvpc2](./doc/awsvpc2.png)

ブラウザで「http://[ip address]:9200/」にアクセスし、上と同じ表示がされればOK。

## <span style="color:#DD8800; ">（AWS）EC2にKibanaをセットアップする

Kibana RPMのrepoを所定フォルダに生成する
``` bash
$ sudo nano /etc/yum.repos.d/kibana.repo
```

kibana.repo への記載内容は以下の通り。
``` bash
[kibana-7.x]
name=Kibana repository for 7.x packages
baseurl=https://artifacts.elastic.co/packages/7.x/yum
gpgcheck=1
gpgkey=https://artifacts.elastic.co/GPG-KEY-elasticsearch
enabled=1
autorefresh=1
type=rpm-md
```

インストールコマンドを実行する
``` bash
$ sudo yum install kibana 
：
：
Installed:
  kibana.x86_64 0:7.15.1-1

Complete!
```

外部アドレスからのアクセスを可能にするために、設定ファイル「kibana.yml」を開く。
```
$ sudo nano /etc/kibana/kibana.yml
```

以下の箇所に追記を行って、ファイルを保存。
``` bash
# To allow connections from remote users, set this parameter to a non-loopback $
# server.host: "localhost"
server.host: "0.0.0.0"   # ← ここを追記
```

システム起動時にKibanaを起動するようにする（systemd）
``` bash
$ sudo /bin/systemctl daemon-reload
$ sudo /bin/systemctl enable kibana.service
```

動作確認。まずはPCを再起動。
``` bash
$ sudo shutdown -r now
```

再起動後、起動状態をチェックする
``` bash
$ sudo systemctl | grep kibana
kibana.service         loaded active running   Kibana
```

以下のコマンドでサービス自体の起動を確認（デフォルトポートは 5601）
``` bash
$ sudo curl http://localhost:5601
```

↑ 特にエラーなど、何もでなければ、おそらく(笑) 問題なし。

外部からのアクセスを確認する。AWSのセキュリティグループで、ポート5601の接続許可を設定する。

![awsvpc3](./doc/awsvpc3.png)


ブラウザで「http://[ip address]:5601/」にアクセスし、下の画面が表示がされればOK。

![kibana](./doc/kibana.png)

VisualStudioCodeのRestClientを使用して、ElasticSearchにIndexを定義する。

``` json 
PUT http://[host_ipaddress]:9200/iot_data/
Content-Type: application/json

{
    "mappings": {
        "properties": {
            "GetDateTime": {
                "type": "date",
                "format": "yyyy-MM-dd HH:mm:ss"
            },
            "Humidity": {
                "type": "float"
            },
            "Temperature": {
                "type": "float"
            }
        }
    }
}
```

## <span style="color:#DD8800; ">（RaspberryPi）AWS Lambda用のファンクションを作成する

作業用のフォルダを作成する。
``` bash
$ cd aws_lambda

$ mkdir airConditionESEntryFunc
$ cd airConditionESEntryFunc
```
直下に、pythonソースファイル [lambda_function.py](./aws_lambda/airConditionESEntryFunc/lambda_function.py) を作成する。  
※ソースコード中の "es_host","es_port","index" は、後ほどlambda上で環境変数として設定する。

このソースファイルに必要なライブラリ「requests」を、カレントディレクトリ上にインストールする。
``` bash
$ pip install requests -t ./
```

ソース＋ライブラリをlambdaへのアップロード用にzip圧縮する。
``` bash
# カレントディレクトリにlambda_function.pyと各種ライブラリがあることを確認
$ ls 
  bin                                 idna-3.3.dist-info
  certifi                             lambda_function.py
  certifi-2021.10.8.dist-info         requests
  charset_normalizer                  requests-2.26.0.dist-info
  charset_normalizer-2.0.7.dist-info  urllib3
  idna                                urllib3-1.26.7.dist-info

$ zip -r airConditionESEntryFunc.zip ./*
```

## <span style="color:#DD8800; ">（AWS）ElasticSerach登録用のLambda関数を作成する

以下の手順でlambda関数を作成する
- 「サービス」から「Lambda」を選択。
- 「関数」>「関数の作成」画面で、以下を指定して「関数の作成」をクリックする。
  - 関数名：「airConditionESEntryFunc」。名称自体は任意だが、前の手順でzip作成した際の、フォルダ名とあわせる
  - ランタイム：Python 3.9
  - アーキテクチャ：x86_64
  - アクセス権限>デフォルトの実行ロールの変更：
    - 「基本的な Lambda アクセス権限で新しいロールを作成」を選択
- 「コード」タブ開く
  - 画面右上の「アップロード元」に「.zip」ファイルを選択する。前の手順で作成したzipファイルを指定して、ソースをアップロードする。
- 「設定」タブ>「アクセス権限」を開く
  - 「実行ロール」に表示されたロール名のリンクをクリック（IAMのロール画面に遷移する）
  - 「ポリシーをアタッチします」をクリックして、次のポリシーを追加
    - `AmazonDynamoDBFullAccess`
    - `AWSLambdaVPCAccessExecutionRole`
- 「設定」タブ>「環境変数」で「編集」ボタンを押して以下の環境変数を追加
  - 「es_host」：EC2の<b><u>`プライベートIPv4アドレス`</u></b>を設定する。
  - 「es_port」：「9200」を設定する
  - 「index」：「iot_data」を設定する
- 「設定」タブ>「VPC」で「編集」ボタンを押して以下の設定を追加
  - 「VPC」「サブネット」「セキュリティグループ」：先の手順で作成したEC2の設定値と同じ値を設定※Lambda自体をVPC内に配置して、そこからVPC内のEC2にリクエストする

次に、EC2のセキュリティグループに、Lambdaからのアクセス(Private内部からのアクセス)を許可するように設定する。

- 「サービス」から「EC2」を選択。
- 「インスタンス」から構築した「EC2」を選択。
- 画面下部で「セキュリティ」を選び、当該セキュリティグループのハイパーリンクから、内容を画面に表示する。
- 「インバウンドルール」タブで、「インバウンドのルールを編集」をクリックする。
- 以下のルールを追加
  - タイプ：カスタムTCP
  - ポート範囲：9200
  - ソース：（開いているセキュリティグループ自身）
  ![secgroup](./doc/secgroupadd.png)


動作確認。
- 「コード」タブ>「テスト」で、「テスト」ボタンに以下の内容を登録して、テスト実行する。
``` json 
{
    "Records": [
        {
            "dynamodb": {
                "NewImage": {
                    "GetDateTime": {
                        "S": "2021-11-03 16:20:18"
                    },
                    "Temperature": {
                        "N": "20.5"
                    },
                    "Humidity": {
                        "N": "72.3"
                    }
                }
            }
        }
    ]
}
```
ブラウザから、KibanaのURLにアクセスし、Discover画面でデータが表示されれば疎通確認としてはOK。

正常に登録されることを確認できたら、以下の手順でDynamoDBテーブルの変更通知とつなげる。

- 「設定」タブ>「トリガー」で「トリガーを追加」ボタンをクリック
  - 「トリガーの設定」で「DynamoDB」を選択。
    - DynamoDBテーブル：「air-condition」
    - トリガーの有効化：チェック

<br>

トリガーが設定されると、1分に1回、ElasticSearchにデータが蓄積されるようになる。


## <span style="color:#DD8800; ">（RaspberryPi）二酸化炭素センサ、液晶ディスプレイを取り付ける

上記で温湿度センサーデータの連携は実現できた。これに加え、以下では二酸化炭素量の計測を行い、温湿度データとともにサーバへの送信、LINEへの通知、グラフ表示を行う。  

新たに、次のパーツを使用する。
- 液晶：Aideepen [SSD1306](https://www.amazon.co.jp/Aideepen-OLED%E3%83%87%E3%82%A3%E3%82%B9%E3%83%97%E3%83%AC%E3%82%A4IIC-OLED%E3%83%A2%E3%82%B8%E3%83%A5%E3%83%BC%E3%83%ABSSD1306-4%E3%83%94%E3%83%B3SPI%E3%82%A4%E3%83%B3%E3%82%BF%E3%83%BC%E3%83%95%E3%82%A7%E3%82%A4%E3%82%B9%E7%94%BB%E9%9D%A2-Arduino%E3%81%AB%E5%AF%BE%E5%BF%9C/dp/B099ZYRJWL/ref=sr_1_1_sspa?keywords=SSD1306&qid=1636469302&sr=8-1-spons&psc=1&spLa=ZW5jcnlwdGVkUXVhbGlmaWVyPUEzNUtHRFFOS0lIODFYJmVuY3J5cHRlZElkPUEwNzM0NzI2Mjk3UUJLRlUyM1lWNSZlbmNyeXB0ZWRBZElkPUEyNEdLQUE4WUFKRkhaJndpZGdldE5hbWU9c3BfYXRmJmFjdGlvbj1jbGlja1JlZGlyZWN0JmRvTm90TG9nQ2xpY2s9dHJ1ZQ==)
- 二酸化炭素センサ：KeyeStudio [CCS811](https://www.amazon.co.jp/KEYESTUDIO-CCS811-Arduino-%E3%82%A2%E3%83%AB%E3%83%89%E3%82%A5%E3%82%A4%E3%83%BC%E3%83%8E-%E3%82%A2%E3%83%AB%E3%83%87%E3%82%A3%E3%83%BC%E3%83%8E/dp/B086HCSM6N?ref_=ast_sto_dp)

RaspberryPiに、以下のように取付を行う。

![取付例1](./doc/SSD1306.png)

![取付例2](./doc/CCS811&SSD1306.png)

取付時のポイント
- 各機器のVIN、GNDは、RaspberryPiの5V、GNDと接続する（動作に4.5V以上が必要なため、電源は3.3Vではなく、5Vの方に接続すること）
- 各機器のSDA、SCLをそれぞれ、RaspberryPiのSDA(Pin#3)、SCL(Pin#5)と接続する。
- さらにCCS811のWAKEとGND同士を接続する。RSTとINTは今回使用しない。

今回のパーツは、I2Cというインターフェイスで接続を行う。機器を接続したら、RaspberryPiのターミナルから以下のコマンドを実行する。
```
$ i2cdetect -y 1
```
これにより、機器の接続状況が確認できる。  
以下のとおり表示されれば、接続OK。
![i2cdetect](./doc/i2cdetect.png)  

表内の値は、それぞれ各機器の接続状態を示している。これらが表示されなければ、上のポイントを参考に、接続を再確認すること。
- アドレス3c … SSD1306(液晶)
- アドレス5a … CCS811(二酸化炭素センサ)

次に、I2Cの通信速度（ボーレート）を変更する。特にCCS811(二酸化炭素センサ)は、RaspberryPiのデフォルト速度100kHzでは動作せず、エラー「Remote I/O Error」が表示されてしまうことがある。

以下のコマンドを実行し、設定を編集する。
``` bash
$ sudo nano /boot/config.txt
```

編集画面が表示されたら、次の部分を編集して、保存する。
![baudrate](./doc/baudrate.png)
```
dtparam=i2c_arm=on,i2c_arm_baudrate=60000
```

編集が終わったら、一度RaspberryPiを再起動する。
``` bash
$ sudo reboot
```

再起動したら、必要なライブラリをPython環境にインストールする。
``` python
# SSD1306用ドライバ インストール
$ pip3 install adafruit-circuitpython-ssd1306 

# CCS811用ドライバ インストール
$ pip3 install adafruit-circuitpython-ccs811 

# board モジュール　インストール
$ pip3 install board

※この後の実行でModuleNotFoundError:No module named 'board'　と結果が出たら
以下コマンドを実行する。　これでダメな場合は2個目の強制インストールを実行する
$ pip3 install adafruit-blinka

$ python3 -m pip install --force-reinstall adafruit-blinka

# 液晶表示用のフォント インストール
$ sudo apt-get install fonts-noto 
```

[こちら](./aircond3.py)のソースを作業フォルダ直下に配置して、実行する  
※ソース上の定義部分「# Mqtt Define」の内容は、前述のデバイスデータエンドポイントや、証明書に置き換えてください。

```
$ python3 aircond3.py
```

以下のように表示されればOK。
![gamen](./doc/WIN_20211110_00_19_55_Pro.jpg)

## <span style="color:#DD8800; ">（AWS）各種サービスを修正
以下の各種サービスに対して、二酸化炭素値を加え、Kibanaのグラフ出力、LINEの通知内容を編集していく（詳細は割愛する）
- IoT Core
- DynamoDB
- Lambda
- ElasticSearch
- Kibana