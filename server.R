function(input, output, server) {
  # ファイル1を入力したとき，ファイル1がExcelファイルならシートを選択するUIを追加する
  observeEvent(input$file1,
               {
                 if (input$file1$datapath %>% str_detect(".xls")) {
                   output$input_file1Sheets <- renderUI({
                     try(selectInput("input$file1_sheet",
                                     "シート名を選択してください",
                                     excel_sheets(input$file1$datapath)),
                         silent = T)
                   })
                 } else {
                   output$input_file1Sheets <- renderText("")
                 }
               })
  
  # ファイル2を入力したとき，ファイル2がExcelファイルならシートを選択するUIを追加する
  observeEvent(input$file2,
               {
                 if (input$file2$datapath %>% str_detect(".xls")) {
                   output$input_file2Sheets <- renderUI({
                     try(selectInput("input$file2_sheet",
                                     "シート名を選択してください",
                                     excel_sheets(input$file2$datapath)),
                         silent = T)
                   })
                 } else {
                   output$input_file2Sheets <- renderText("")
                 }
               })
  
  # ファイル1を表示するボタンを押したとき，タブ2にファイル1の内容を表示する
  observeEvent(input$file1showButton,
               {
                 file1Input <-
                   reactive({
                     inputControl(input$file1$datapath, input$file1_sheet)
                   })
                 
                 if (length(file1Input()) <= 1) {
                   output$error1 <- try(renderText(file1Input()), silent = T)
                 } else {
                   output$file1_dt <- try(renderDataTable({
                     datatable(
                       file1Input(),
                       colnames = 1:ncol(file1Input()),
                       options = list(
                         scrollX = TRUE,
                         scrollCollapse = TRUE,
                         pageLength = 50,
                         paging = FALSE
                       )
                     )
                   }), silent = T)
                 }
               })
  
  # ファイル2を表示するボタンを押したとき，タブ3にファイル2の内容を表示する
  observeEvent(input$file2showButton,
               {
                 file2Input <-
                   reactive({
                     inputControl(input$file2$datapath, input$file2_sheet)
                   })
                 
                 if (length(file2Input()) <= 1) {
                   output$error2 <- try(renderText(file2Input()), silent = T)
                 } else {
                   output$file2_dt <- try(renderDataTable({
                     datatable(
                       file2Input(),
                       colnames = 1:ncol(file2Input()),
                       options = list(
                         scrollX = TRUE,
                         scrollCollapse = TRUE,
                         pageLength = 50,
                         paging = FALSE
                       )
                     )
                   }), silent = T)
                 }
               })
  
  # ファイル1とファイル2を比較して違いを出力する
  observeEvent(input$runCompare,
               {
                 # ファイルを読み込み
                 file1Input <-
                   reactive({
                     inputControl(input$file1$datapath, input$file1_sheet)
                   })
                 file2Input <-
                   reactive({
                     inputControl(input$file2$datapath, input$file2_sheet)
                   })
                 
                 # ファイル1と2に入力がないときは何もしない
                 if (file1Input() %>% length <= 1 |
                     file2Input() %>% length <= 1) {
                   # 何もしない
                 } else {
                   # ファイル1と2の中身がある場合には比較を行い，除かれた行をrd1，rd2に，異なる要素があるものをdifに入力する
                   temp <- detectDifLines(file1Input(), file2Input())
                   dif <- temp$difference_in_two_df
                   rd1 <- temp$removed_d1
                   rd2 <- temp$removed_d2
                 }
                 
                 output$diff_dt <- renderDataTable({
                   if (is.null(dif)) {
                     data.frame(no_dif = '<b><font color="red">2つのシートに置換はありません</b></font>') %>%
                       datatable(escape = FALSE)
                   } else {
                     # 異なる要素数が多すぎるときには，20文字+...で表示する（後でdifを使うので，dfを別オブジェクトにコピー）
                     dif1 <- dif
                     dif1$d1_difvalue <- ifelse(dif1$d1_difvalue %>% str_length > 10, dif1$d1_difvalue %>% str_sub(1, 20) %>% paste0("..."), dif1$d1_difvalue)
                     dif1$d2_difvalue <- ifelse(dif1$d2_difvalue %>% str_length > 10, dif1$d2_difvalue %>% str_sub(1, 20) %>% paste0("..."), dif1$d2_difvalue)
                     datatable(dif1,
                               colnames = c("ファイル1の行", "ファイル1の異なる要素", "ファイル2の行", "ファイル2の異なる要素"),
                               rownames = FALSE,
                               options = list(
                                 scrollX = TRUE,
                                 scrollCollapse = TRUE,
                                 pageLength = 50,
                                 paging = FALSE
                               ))
                   }
                 })
                 
                 # 削除行について表示する
                 output$removed_dt1 <- renderText({
                   if (is.null(rd1)) {
                     'ファイル2で削除された行はありません'
                   } else {
                     paste0("ファイル2にないファイル1の行は", paste0(rd1, collapse=","), "です")
                   }
                 })
                 
                 output$removed_dt2 <- renderText({
                   if (is.null(rd2)) {
                     'ファイル1で削除された行はありません'
                   } else {
                     paste0("ファイル1にないファイル2の行は", paste0(rd2, collapse=","), "です")
                   }
                 })
                 

                   
                 output$file1_dt <- renderDataTable({
                   d1 <- file1Input()
                   
                   if(!is.null(dif)){
                     # ファイル1とファイル2の異なる要素をラベルして表示する
                     # ラベル処理1: ファイル1と2の置換要素を赤表示にする
                     for(i in 1:nrow(dif)){
                       dif1_row <- dif[i, 1]
                       dif1_cont <- dif[i, 2] %>% str_split(",") %>% unlist() %>% as.character()
                       
                       for(k in 1:length(dif1_cont)){
                         if(d1[dif1_row, ] %>% str_detect(dif1_cont[k]) %>% na.omit %>% sum != 0){ # ココがおかしい NAが交じると計算できない
                         d1[dif1_row, d1[dif1_row, ] %>% str_detect(dif1_cont[k])] <- paste0('<b><font color="red">', dif1_cont[k], '</b></font>')
                       }}
                     }
                   }
                   
                   rd1 <- temp$removed_d1
                   deleted_in_d2 <- numeric(nrow(d1))
                   
                   if(length(rd1) > 0){
                    deleted_in_d2[rd1] <- 1
                   }
                   
                   d1 <- cbind(d1, deleted_in_d2)
                   datatable(d1,
                             escape = FALSE,
                             colnames = 1:ncol(d1),
                             rownames = FALSE,
                             options = list(
                               scrollX = TRUE,
                               scrollCollapse = TRUE,
                               pageLength = 50,
                               paging = FALSE
                             )) %>% formatStyle(
                               'deleted_in_d2',
                               target = 'row',
                               fontWeight = styleEqual(c(0, 1), c('normal', 'bold')),
                               Color = styleEqual(c(0, 1), c('black', 'red'))
                             )
                 })
                 
                 
                 output$file2_dt <- renderDataTable({
                   d2 <- file2Input()
                   
                   if(!is.null(dif)){
                     # ファイル1とファイル2の異なる要素をラベルして表示する
                     # ラベル処理1: ファイル1と2の置換要素を赤表示にする
                     for(i in 1:nrow(dif)){
                       dif2_row <- dif[i, 3]
                       dif2_cont <- dif[i, 4] %>% str_split(",") %>% unlist() %>% as.character()
                       
                       for(k in 1:length(dif2_cont)){
                         if(d2[dif2_row, ] %>% str_detect(dif2_cont[k]) %>% na.omit %>% sum != 0){ # ココがおかしい
                         d2[dif2_row, d2[dif2_row, ] %>% str_detect(dif2_cont[k])] <- paste0('<b><font color="red">', dif2_cont[k], '</b></font>')
                         }}
                     }
                   }
                   
                   rd2 <- temp$removed_d2
                   deleted_in_d1 <- numeric(nrow(d2))
                   if(length(rd2) > 0){
                     deleted_in_d1[rd2] <- 1
                   }
                   
                   d2 <- cbind(d2, deleted_in_d1)
                   datatable(d2,
                             escape = FALSE,
                             colnames = 1:ncol(d2),
                             rownames = FALSE,
                             options = list(
                               scrollX = TRUE,
                               scrollCollapse = TRUE,
                               pageLength = 50,
                               paging = FALSE
                             )) %>% formatStyle(
                               'deleted_in_d1',
                               target = 'row',
                               fontWeight = styleEqual(c(0, 1), c('normal', 'bold')),
                               Color = styleEqual(c(0, 1), c('black', 'red'))
                             )
                 })
                 
                 d1 <- NULL
                 d2 <- NULL
                 write.table(data.frame(), "temp1.txt", quote=F)
                 write.table(data.frame(), "temp2.txt", quote=F)
               })
}