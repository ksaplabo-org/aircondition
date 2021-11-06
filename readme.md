# DHT11 MQTT To AWS.IoTCore
## ライブラリの取得
- GitからDHT11のライブラリを取得する。
```
$ sudo git clone https://github.com/szazo/DHT11_Python.git
```

- サンプル起動
```
$ sudo python3 ./DHT11_Python/example.py
```

## 下地環境の作成(RaspberryPi)
- サンプルをコピー 
$ sudo cp ./DHT11_Python/example.py ./aircond.py

- gitファイル削除
```
$ cd DHT11_Python
$ rm -rf .git
```

- ライブラリ本体のフォルダをひとつ上に移動
```
$ cd ..
$ sudo mv -f ./DHT11_Python/dht11/ ./dht11
```

- 不要フォルダ削除
```
$ sudo rm -rf ./DHT11_Python
```

## クラウド上でモノ情報を作成(AWS IoTCore)
### モノの作成～証明書ダウンロード
- モノの登録 
  - 「管理」から「モノ」(Thing)を選択し、「モノを作成」をクリック
  - 「１つのモノを作成」を選んで「次へ」
  - 「モノの名前」を入力（今回は「air-condition-pi」）して「次へ」
  - 「デバイス証明書」で「新しい証明書を自動生成 (推奨)」を選択して「次へ」
  - 「証明書にポリシーをアタッチ」で「ポリシーを作成」をクリック。以下の内容を入力して「作成」をクリック。
    - 名前：任意（例：air-condition-pi-policy）
    - アクション：「iot:*」
    - リソースARN：「*」
    - 効果：「許可」をチェック
  - ひとつ前の画面（証明書にポリシーをアタッチ）に戻り、作成したポリシーを選択して「モノを作成」をクリック。
  - ここで表示される証明書、プライベートキー、パブリックキーをすべてダウンロードする。
- IoTエンドポイントの確認
  - 左側のメニューツリーの、一番下の方にある「設定」をクリック
  - 「デバイスデータエンドポイント」にあるエンドポイントをメモ。

## MQTTプログラム(RaspberryPi)
### ライブラリのインポート
- MQTTのクライアントライブラリをダウンロード
```
$ pip3 install paho-mqtt python-etcd
```

### ソース修正
- 必要なライブラリのインポートを追記  
以下のコードを追記
```
import paho.mqtt.client
import json
import asyncio
import ssl
``` 

- MQTTエンドポイント、証明書、鍵等を定義  
以下のコードを追記
```
# Mqtt Define
AWSIoT_ENDPOINT = "***[エンドポイント]***.iot.ap-northeast-1.amazonaws.com"
MQTT_PORT = 8883
MQTT_TOPIC_PUB = "mqttAirCondition"
MQTT_ROOTCA = "/home/pi/Downloads/AmazonRootCA1.pem"
MQTT_CERT = "/home/pi/Downloads/***[証明書]***-certificate.pem"
MQTT_PRIKEY = "/home/pi/Downloads/***[秘密鍵]***-private.pem"
```

- 同一行に、TabとSpaceを混同させないこと。
- 証明書、秘密鍵ファイルの名前を間違えないこと。

- その他、もろもろ修正

```
$ python3 aircond2.py
mqtt connected.
subscribe topic : topicAirConditionSub
datetime:2021/10/30 14:27:59 Temperature: 19.8 C Humidity: 46.0 %
datetime:2021/10/30 14:28:00 Temperature: 20.0 C Humidity: 44.0 %
datetime:2021/10/30 14:28:01 Temperature: 20.0 C Humidity: 44.0 %
```

### AWSでのサブスクライブ（受信）確認
- AWSコンソールから「AWS IoT」サービスを開き、「テスト」>「MQTTテストクライアント」を選択する。
- 「トピックをサブスクライブする」で、「トピックのフィルター」に「topicAirCondition」と入力して、「サブスクライブ」を押す。
- 以下のように表示されれば、受信OK。
```
topicAirCondition
November 01, 2021, 22:23:12 (UTC+0900)
{
  "GetDateTime": "2021-11-01 22:23:09",
  "Temperature": 19.8,
  "Humidity": 70
}
```

## IoT CoreにDynamoDBへの登録ルールを設定(AWS IotCore)
### Actionルール追加
- 「ACT」で「ルール」を指定して、以下の流れでルールを追加する。
  - ルール名は任意（「air_condition_entry_rule」）
  - ルールクエリステートメントに、以下の内容を設定。
  >「SELECT GetDateTime,Temperature,Humidity FROM 'topicAirCondition'」
  - アクションに「DynamoDBテーブル（DynamoDBv2）の複数列にメッセージを分割する。」を選択。
  - 新しいリソースとして、DynamoDBに任意のテーブルを作成する。
    - テーブル名の名称は任意（「air-condition-data」）
    - パーティションキーは「GetDateTime」とする
    - 「テーブルの作成」ボタンをクリックする。
  - ロールの作成では「DynamoDB:PutItem」ポリシーを持つロールが必要。

### DynamoDBへのデータ登録確認
- DynamoDBサービスで、テーブル>項目の表示を行って、登録が行われていることを確認する。
## AWS Lambdaに関数を追加
### DynamoDBのStreamを有効化
- トリガーにDynamoDBを指定
- 設定 - アクセス権で実行ロールを作成。ロールには、以下の2つを登録
  - AmazonDynamoDBFullAccess
  - AWSLambdaVPCAccessExecutionRole
### AWS 
```
$ # elasticsearchライブラリをローカルに取得
$ pip install elasticsearch -t ./elasticsearch

$ # zip化する
$ zip -r elasticsearch.zip elasticsearch/
```

# Github 
### サインイン
[ここからSign inを行う](https://github.com/login)
### アクセストークンの取得
- 画面右上のサブメニュー（三本線をクリック->「Settings」を選択）
- 左のツリーから「Developer Settings」を選択
- 続いて「Personal access tokens」を選択
- 右上の「Generate new token」を選択
- トークン名と権限を設定（Repoをチェック）して、Generate Tokenボタンをクリック
- 画面にトークン（例「ghp\*\*\*\*\*Q6yth8kS1YZvHMlk9fQIgELJ5a\*\*\*tCpL」）
が表示されるので、メモする。

### 基本操作
#### 環境設定
```
$ git config --global user.email [メールアドレス]  

$ git config --global user.name [名前] 
``` 

#### 新規のプロジェクト作成
- PG作成  
  なんやかんや作る

- ローカルリポジトリ初期化
```
$ cd [作業フォルダ]
$ git init
```
- リモートレポジトリ作成  
  ※この操作は、Webページで行う。
  - ブラウザで、GitHubページにログイン
  - Repositoriesページで「New」をクリック
  - 必要情報を入力して、作成する
  - リモートリポジトリアドレスを取得（.git）
- リモートリポジトリをOriginに設定
```
$ git remote add origin [リモートリポジトリアドレス（.git）]
```
- ローカルリポジトリへ追加
```
$ git add .
```
- ローカルリポジトリへコミット
$ git commit -m "[コメント。自由記載だが必須]```
- リモートリポジトリへ追加
```
$ git push origin master
```

#### 既存プロジェクトの取得
```
>$ git clone [レポジトリ名]
```
