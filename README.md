# Heroku Installer

## これはなに? ##
  任意のGitリポジトリをHerokuに直接デプロイします。  
  以下のURLをリポジトリのREADMEに貼るなどしてデプロイを加速しましょう。  
    `http://heroku-installer.gkbr.me/install/git://path/to/repo.git`

## .heroku-installer について ##
  リポジトリに `.heroku-installer` というファイルを配置することでデプロイの設定ができます。  
  フォーマットは以下のようなYAMLとなります。

    addons:                # ここにはインストールしたいアドオンを列挙します。
      - shared-database
    config:                # ここには設定したい環境変数を列挙します。
      key: value
    script:                # ここにはデプロイ後、実行したいコマンドを列挙します。
      - rake db:setup
