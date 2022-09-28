# ==================================================== #
#        Elasticsearch & kibana install shell
# ---------------------------------------------------- #
#   このフォルダに以下のファイルも併せて配置してください。
#      ・elasticsearch.repo
#      ・kibana.repo
# ==================================================== #

# yumリポジトリ更新
sudo yum update -y

# java8 OpenJDK
sudo yum install java-1.8.0-openjdk.x86_64 -y

# GPG-KEYをローカルリポジトリにインポート
sudo rpm --import https://artifacts.elastic.co/GPG-KEY-elasticsearch

# elasticsearch.repoをコピー
sudo chmod 777 ./elasticsearch.repo 
sudo cp ./elasticsearch.repo /etc/yum.repos.d/

# elasticsearch インストール
sudo yum install --enablerepo=elasticsearch elasticsearch -y

# elasticsearch.yml 設定変更
sudo sh -c "echo 'network.host: 0.0.0.0' >> /etc/elasticsearch/elasticsearch.yml"
sudo sh -c "echo 'discovery.type: single-node' >> /etc/elasticsearch/elasticsearch.yml"
sudo sh -c "echo 'xpack.security.enabled: false' >> /etc/elasticsearch/elasticsearch.yml"

# elasticsearch 自動起動
sudo /bin/systemctl daemon-reload
sudo /bin/systemctl enable elasticsearch.service

# kibana.repoをコピー
sudo chmod 777 ./kibana.repo 
sudo cp ./kibana.repo /etc/yum.repos.d/

# kibana インストール
sudo yum install kibana -y

# kibana.yml 設定変更
sudo sh -c "echo 'server.host: \"0.0.0.0\"' >> /etc/kibana/kibana.yml"

# kibana 自動起動
sudo /bin/systemctl daemon-reload
sudo /bin/systemctl enable kibana.service

# 再起動
sudo shutdown -r now
