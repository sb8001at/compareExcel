fluidPage(
  theme = bs_theme(version = 5, bootswatch = "united"),
  nav_bar_fixed = TRUE,
  navbarPage("Excelファイル比較",
             tabPanel(
               "", sidebarLayout(
                 sidebarPanel(
                   width = 3,
                   fileInput("file1", "1つ目のファイルを選択してください"),
                   uiOutput("input_file1Sheets"),
                   actionButton("file1showButton", "ファイル1を表示"),
                   hr(),
                   br(),
                   fileInput("file2", "2つ目のファイルを選択してください"),
                   uiOutput("input_file2Sheets"),
                   actionButton("file2showButton", "ファイル2を表示"),
                   hr(),
                   br(),
                   actionBttn(
                     inputId = "runCompare",
                     label = "比較を実行",
                     style = "material-flat",
                     color = "primary"
                   ),
                   
                   hr(),
                   br(),
                   p("「異なる行」では，d1が一つ目のファイル，d2が2つ目のファイルを示します")
                 ),
                 
                 mainPanel(
                   id = "mainpaneltabs",
                   width = 9,
                   tabsetPanel(
                     tabPanel(
                       "差のある項目",
                       hr(),
                       h5("ファイル2に存在しないファイル1の行"),
                       verbatimTextOutput("removed_dt1"),
                       hr(),
                       h5("ファイル1に存在しないファイル2の行"),
                       verbatimTextOutput("removed_dt2"),
                       hr(),
                       h5("ファイル1とファイル2で要素が異なる行"),
                       dataTableOutput("diff_dt", height =
                                         "10em")
                     ),
                     tabPanel(
                       "ファイル1のシート",
                       textOutput("error1"),
                       dataTableOutput("file1_dt", height = "40em")
                     ),
                     tabPanel(
                       "ファイル2のシート",
                       textOutput("error2"),
                       dataTableOutput("file2_dt", height = "40em")
                     ),
                     
                    tabPanel(
                      "使い方",
                      h4("はじめに"),
                      p("このページは2つのExcelファイルを比較することを目的として作成しました．ファイル1，ファイル2を選択し，「ファイルを比較」を押すことでファイルの中身を比較することができます．"),
                      br(),
                      h4("使い方"),
                      p("まず，下の図の欄をクリックして，読み込むファイルを選択します．ファイルはExcel，コンマ切りテキスト（CSV），タブ切りテキスト（TSV）に対応しています．"),
                      img(src="ExcelCompare_top.png"),
                      p("（ただし，CSV，TSVのエンコーディングはUTF-8である必要があります．Windowsを使用している場合にはメモ帳で「別名で保存→下のエンコードでUTF-8を選択」して，エンコーディングを変更してください．）"),
                      p("ファイルを選択した状態で，「ファイルを表示」を押すと，そのファイルのタブにデータが表示されます．"),
                      p("2つのファイルを選択し，「ファイルを比較」を押すと，ファイル1にのみある行，ファイル2にのみある行，ファイル1と2で異なる要素を表示します．"),
                      p("この状態で上のファイルタブを選択すると，異なる部分が赤文字で表示されます．"),
                      p("ファイル1がExcel，ファイル2がCSVなどの場合にも比較はできるはずですが，エラーが出ることもあります．"),
                      
                      br(),
                      h4("作成の動機"),
                      p("弊社では，Excelで他社からデータを貰い，解析をしています．データの解析は2名で行うのですが，その際に別のExcelファイルにデータをコピペします．そして，コピペしたデータを2名で読み合わせ，間違いが無いことを確認しています．"),
                      p("しかし，Excelを印刷して目視で調べても，違いがあるのか確実に検出できませんし，そもそもコピペを2人で目視検品することに意味があるのか，謎ではあります．"),
                      p("21世紀も20年を超え，普通の人にもPCが扱える時代になって四半世紀，文明の利器であるプログラムも使わず，目視チェックしているのはどうだろう？と感じました．"),
                      p("文明人らしく，きちんとプログラムで比較したい，でも良いツールはない，ということで，手元にあったRとShinyでExcelを比較するツールを作成しました．"),
                      
                      br(),
                      h4("動作と仕組み"),
                      p("ツールの作成にはRとShinyを用いています．中身は単純で，"),
                      p("① Excelファイルを文字列として読み込んでテキストファイルとして保存"),
                      p("② Bashのsdiffを叩いてテキストファイルの差を検出"),
                      p("③ sdiffの出力を読み解いてExcelのページをDTで表示"),
                      p("しているだけです．部分的にやや煩雑な処理を行っているので（Rしか使ってないので仕方ないですが），動作が遅い等問題もありますが，一応使える形となっています．"),
                      p("残念ながらCSV・TSVの読み込みのエンコーディング分析自動化（rvestのguess_encodingを使って実装しようとした）はうまくいっておらず，Windowsユーザーではエラーが出やすくなっています．"),
                      p("また，sdiffを使う関係で，「列の挿入」があると分析に時間がかかり，不正確な結果が帰ってくる仕組みになっています．"),
                      p("「Excel上で見やすくするためにA列をなんとなく挿入する」みたいな使い方をすると，比較結果が不正確になります．余計な行はなるべく挿入しないようにしてください．"),
                      
                      br(),
                      
                      h4("バージョン情報"),
                      p("ver.0.1 公開，未バリデーション状態"),
                      
                      br(),
                      
                      h4("使用したツール"),
                      p("本ツールにはR，Shiny，tidyverse，stringr，readxl，DT，bslib，ShinyWidgetsを利用しています．"),
                      
                      actionButton(inputId='Rlink', label="CRAN", 
                                   icon = icon("link"), 
                                   onclick ="window.open('https://cran.r-project.org/', '_blank')"),
                      actionButton(inputId='Shinylink', label="Shiny", 
                                   icon = icon("link"), 
                                   onclick ="window.open('https://shiny.rstudio.com/', '_blank')"), 
                      actionButton(inputId='tidyverseLink', label="tidyverse", 
                                   icon = icon("link"), 
                                   onclick ="window.open('https://www.tidyverse.org/', '_blank')"),
                      actionButton(inputId='stringrLink', label="stringr", 
                                   icon = icon("link"), 
                                   onclick ="window.open('https://stringr.tidyverse.org/', '_blank')"),
                      actionButton(inputId='readxllink', label="readxl", 
                                   icon = icon("link"), 
                                   onclick ="window.open('https://readxl.tidyverse.org/', '_blank')"),
                      actionButton(inputId='DTlink', label="DT", 
                                   icon = icon("link"), 
                                   onclick ="window.open('https://rstudio.github.io/DT/', '_blank')"),
                      actionButton(inputId='bslibLink', label="bslib", 
                                   icon = icon("link"), 
                                   onclick ="window.open('https://rstudio.github.io/bslib/', '_blank')"),
                      actionButton(inputId='ShinywidgetsLink', label="ShinyWidgets", 
                                   icon = icon("link"), 
                                   onclick ="window.open('https://shinyapps.dreamrs.fr/shinyWidgets', '_blank')")
                    )
                   )
                 )
               )
             ))
  
)
