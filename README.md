
# NAME

zipconv

# WHAT IS THIS?

郵政提供のKEN_ALL.CSVを変換するツールです。
KEN_ALL.CSVはそのままだと扱いづらいため、このツールで自分の使いやすい形式に変換するとよいでしょう。
このツールを使えば、たとえばCSVのカラム位置を入れ替えたり、SQLのINSERT文に変換したりする事ができます。

# INSTALL

perlの標準ライブラリのみで動作するので、とくにインストール作業は必要ありません。
zipconv.plをチェックアウトしてご利用ください。

# DESCRIPTION

**使い方**

    perl zipconv.pl KEN_ALL.CSV > output.txt
    perl zipconv.pl --template=Template.txt > output.txt
    perl zipconv.pl --template=ZipTableDML.txt --prefmst=PrefMST.txt --charset=UTF8 > output.sql

**オプション**

    --template=? 出力テンプレートファイル（未指定時はCSV）
    --charset=?  出力文字セット（未指定時はCP932）
    --prefmst=?  都道府県マスタ。（任意）

**テンプレート**

概要:
    1レコードずつテンプレート変数が値に置換されて出力されます。
    レコード間には区切り文字はなにも出力しません。
  
変数:
    ROWID     KEN_ALL.CSVの行番号
    ZIP1      郵便番号上桁
    ZIP2      郵便番号下桁
    PREF      都道府県
    PREF_KANA 都道府県カナ
    PREF_ID   都道府県ID（--prefmst指定時に使えます）
    CITY      市区
    CITY_KANA 市区カナ
    TOWN      町村番地
    TOWN_KANA 町村番地カナ

例:
    デフォルトで使われるテンプレートは以下のようなものです。
    %%ROWID%%,%%ZIP1%%,%%ZIP2%%,%%PREF%%,%%PREF_KANA%%,%%CITY%%,%%CITY_KANA%%,%%TOWN%%,%%TOWN_KANA%%<\x0D\x0A>

都道府県マスタの例:
    ※CP932で記述すること。
    北海道<\t>1<\n>
    青森県<\t>2<\n>
    岩手県<\t>3<\n>

# EXAMPLE

exampleディレクトリにサンプルがありますので試してみてください。
KEN_ALL.CSV は郵政サイトからダウンロードしてください。

* KEN_ALL.CSV 郵政提供のCSV
* ZipTableDML.txt 変換テンプレート
* PrefMST.txt 都道府県マスタファイル

以下のコマンドでサンプルを実行できます。

    perl zipconv.pl --template=ZipTableDML.txt --prefmst=PrefMST.txt --charset=UTF8 > output.sql

# CHANGELOG

* 2011/01/12 初版

# AUTHOR

* ryer
