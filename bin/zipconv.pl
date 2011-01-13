#! perl

# 郵政提供のKEN_ALL.CSVは使いづらいので
# 扱いやすい形に編集を行います
# 
# 使い方:
#   perl zipconv.pl KEN_ALL.CSV > output.txt
#   perl zipconv.pl --template=ZipTableDML.txt --charset=UTF8 > ZipTableDML.sql
# 
# オプション:
#   --template=? 出力テンプレートファイル（未指定時はCSV）
#   --charset=?  出力文字セット（未指定時はCP932）
#   --prefmst=?  都道府県マスタ。（任意）

package zipconv;

use strict;
use warnings;
use utf8;
use Getopt::Long;
use Pod::Usage;
use IO::File;
use Encode;
use Encode::JP::H2Z;

use constant DEFAULT_CHARSET => 'CP932';
use constant DEFAULT_TEMPLATE => "%%ROWID%%,%%ZIP1%%,%%ZIP2%%,%%PREF%%,%%PREF_KANA%%,%%CITY%%,%%CITY_KANA%%,%%TOWN%%,%%TOWN_KANA%%\x0D\x0A";

my %options;
GetOptions(
    \%options,
    "template:s",
    "charset:s",
    "prefmst:s"
);

# 入力の設定
my $input = IO::File->new($ARGV[0]);
if (! $input) {
    die("could not open KEN_ALL.CSV: $ARGV[0]");
}
binmode($input, ":raw:encoding(CP932)" );

# 出力の設定
my $outputCharset = DEFAULT_CHARSET;
if ($options{'charset'}) {
    $outputCharset = $options{'charset'};
}
binmode(STDOUT, ":raw:encoding($outputCharset)" );

# テンプレートの設定
my $templateImage = DEFAULT_TEMPLATE;
if ($options{'template'}) {
    local $/ = undef;
    my $fh = IO::File->new($options{'template'});
    binmode($fh, ":encoding($outputCharset)" );
    $templateImage = <$fh>;
    $fh->close();
}

# 都道府県マスタの設定
my %PREF2ID = ();
if ($options{'prefmst'}) {
    my $fh = IO::File->new($options{'prefmst'});
    binmode($fh, ":raw:encoding(CP932)" );
    while (my $line = <$fh>) {
        $line =~ s/\x0D?\x0A$//;
        my($val, $id) = split("\t", $line, 2);
        $PREF2ID{$val} = $id;
    }
    $fh->close();
}

# Win32
binmode(STDERR, ":encoding(CP932)" );

# メインループ
my $uid = 1;
while (my $line = $input->getline()) {
    # 0 全国地方公共団体コード(JIS X0401、X0402)………　半角数字
    # 1 (旧)郵便番号(5桁)………………………………………　半角数字
    # 2 郵便番号(7桁)………………………………………　半角数字
    # 3 都道府県名　…………　半角カタカナ(コード順に掲載)　(注1)
    # 4 市区町村名　…………　半角カタカナ(コード順に掲載)　(注1)
    # 5 町域名　………………　半角カタカナ(五十音順に掲載)　(注1)
    # 6 都道府県名　…………　漢字(コード順に掲載)　(注1,2)
    # 7 市区町村名　…………　漢字(コード順に掲載)　(注1,2)
    # 8 町域名　………………　漢字(五十音順に掲載)　(注1,2)
    # 9 一町域が二以上の郵便番号で表される場合の表示　(注3)　(「1」は該当、「0」は該当せず)
    # 10 小字毎に番地が起番されている町域の表示　(注4)　(「1」は該当、「0」は該当せず)
    # 11 丁目を有する町域の場合の表示　(「1」は該当、「0」は該当せず)
    # 12 一つの郵便番号で二以上の町域を表す場合の表示　(注5)　(「1」は該当、「0」は該当せず)
    # 13 更新の表示（注6）（「0」は変更なし、「1」は変更あり、「2」廃止（廃止データのみ使用））
    # 14 変更理由　(「0」は変更なし、「1」市政・区政・町政・分区・政令指定都市施行、「2」住居表示の実施
    #              「3」区画整理、「4」郵便区調整、集配局新設、「5」訂正、「6」廃止(廃止データのみ使用))
    my @input = csv2values($line);
    
    if ($input[5] eq 'ｲｶﾆｹｲｻｲｶﾞﾅｲﾊﾞｱｲ') {
        $input[5] = '';
        $input[8] = '';
    }
    
    $input[2] =~ m/^(\d\d\d)(\d+)$/;
    my $zip1 = $1;
    my $zip2 = $2;
    
    my %row = ();
    $row{'ROWID'} = $uid++;
    $row{'ZIP1'} = $zip1;
    $row{'ZIP2'} = $zip2;
    $row{'PREF_KANA'} = h2z($input[3]);
    $row{'PREF'} = $input[6];
    $row{'CITY_KANA'} = h2z($input[4]);
    $row{'CITY'} = $input[7];
    $row{'TOWN_KANA'} = h2z($input[5]);
    $row{'TOWN'} = $input[8];
    
    if ($options{'prefmst'}) {
        $row{'PREF_ID'} = $PREF2ID{ $input[6] };
        if (! $row{'PREF_ID'}) {
            die("insufficient pref in prefmst: ".$input[6]);
        }
    }
    
    rowOutput(\%row);
}

# CSV行を値のリストに変換（おーざっくさめ謹製）
# @param string csv
# @return Array
sub csv2values {
    my($csv) = @_;
    $csv =~ s/(?:\x0D\x0A|[\x0D\x0A])?$/,/;
    return map {/^"(.*)"$/ ? scalar($_ = $1, s/""/"/g, $_) : $_}
                ($csv =~ /("[^"]*(?:""[^"]*)*"|[^,]*),/g);
}

# テンプレートにより値変換し出力
# @param Array values
# @return string
sub rowOutput {
    my($row) = @_;
    
    my $img = $templateImage;
    while (my($name,$value) = each(%$row)) {
        $img =~ s/%%$name%%/$value/sg;
    }
    
    STDOUT->print($img);
}

# Unicode::Japanese::h2z
sub h2z{
    my($v) = @_;
    
    $v = Encode::encode("euc-jp", $v);
    Encode::JP::H2Z::h2z(\$v);
    return Encode::decode("euc-jp", $v);
}
