import decimal
import boto3
import os

# 事前設定用
table_name = os.environ["table_name"]

def lambda_handler(event, context):
    # TODO implement
    for record in event['Records']:
        #データ取得
        tm = record['dynamodb']['NewImage']['GetDateTime']['S']
        tmp = record['dynamodb']['NewImage']['Temperature']['N']
        hum = record['dynamodb']['NewImage']['Humidity']['N']

        # 不快指数＝0.81×気温+0.01×湿度x(0.99×温度－14.3)+46.3
        diFloat = 0.81 * float(tmp) + 0.01 * float(hum) * (0.99 * float(tmp) - 14.3) + 46.3
        di = decimal.Decimal(str(diFloat)).quantize(decimal.Decimal('0.0'))

        #登録データ作成
        registerItem = {
            "GetDateTime": tm,
            "DiscomfortIndex": di
        }

        try:
            # ⑨DynamoDBへのデータ登録
            dynamo = boto3.resource('dynamodb')
            dynamo_table = dynamo.Table(table_name)
            dynamo_table.put_item(Item=registerItem)

            print("Succeeded.")
            return

        except Exception as e:
            print("Failed.")
            print(e)
            return

#不快指数   体感

#～55       寒い
#55〜60     肌寒い
#60〜65     何も感じない
#65〜70     快い
#70〜75     暑くない
#75〜80     やや暑い
#80〜85     暑くて汗が出る
#85～       暑くてたまらない