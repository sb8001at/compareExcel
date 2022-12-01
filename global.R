library(shiny)
library(tidyverse)
library(readxl)
library(stringr)
library(DT)
library(bslib)
library(shinyWidgets)

#browser.path = file.path("C:/Program Files (x86)/Microsoft/Edge/Application/msedge.exe")
#options(browser = browser.path)

# データフレームをを読み込み，比較結果を返す関数（LinuxだとUTF-8，WindowsだとCP932（Shift-JIS）を選択しないといけない？）
compareTextfiles <- function(d1,
                             d2) {
  write.table(
    d1,
    "temp1.txt",
    sep = ",",
    col.names = F,
    row.names = F,
    quote = F,
    fileEncoding = "UTF-8"
  )
  write.table(
    d2,
    "temp2.txt",
    sep = ",",
    col.names = F,
    row.names = F,
    quote = F,
    fileEncoding = "UTF-8"
  )
  
  # Powershellでスクリプトを実行し，結果をテキストファイルに保存
  temp3 <- system("sdiff -s temp1.txt temp2.txt", intern=T) %>% suppressWarnings
  
  if(temp3 %>% length != 0){
    # 結果を処理する
    different_row <- temp3[str_detect(temp3, "\\|")] %>% str_remove_all("\\t")
    removed_row <- temp3[!str_detect(temp3, "\\|")] %>% str_remove_all("\\t")
    
    if(length(different_row)>0){
      different_row <- different_row %>% str_split("\\|") %>% do.call("rbind", .) %>% as.data.frame
      colnames(different_row) <- c("d1", "d2")
    } else {different_row <- NULL}
    
    
    removed_row_df <- ifelse(str_detect(removed_row, "<"), "d1", "d2")
    removed_row <- removed_row %>% str_remove_all("<") %>% str_remove_all(">") %>% str_remove_all(" ")
    removed_row <- data.frame(df = removed_row_df, value = removed_row)
    removed_row_d1 <- removed_row %>% filter(df == "d1")
    removed_row_d2 <- removed_row %>% filter(df == "d2")
    
    out <- list(differentrows = different_row, removed_d1 = removed_row_d1, removed_d2 = removed_row_d2)
  } else {
    out <- NULL
  }
  return(out)
}

# どちらのデータのどの行がCompare-Objectで検出されているかを調べ，compareTextfilesの出力に追記する関数
detectDifLines <- function(d1, d2) {
  temp <- compareTextfiles(d1, d2)
  
  if(!is.null(temp)){
    out1 <- c()
    out2 <- c()
    diff_df <- c()
    
    if(!is.null(temp$differentrows)){
      # 値が異なる行（differentrows）を処理し，異なる行，異なる値を取得する
      for(i in 1:nrow(temp$differentrows)){
        dr_d1_value <- temp$differentrows[i, 1] %>% str_split(",") %>% unlist %>% .[.!=""] # differentrowsの出力をコンマ切りし，空の要素を取り除く
        dr_d2_value <- temp$differentrows[i, 2] %>% str_split(",") %>% unlist %>% .[.!=""] 
        
        # データの行とsdiffの返り値の間の共通の要素の数がsdiffの返り値の要素数より2小さい値より大きいとき，その行を記録する
        # 変な処理ではあるが，何故かsdiffの要素数より短くなることがあるので，-2している
        for(k in 1:nrow(d1)){
          if(intersect(dr_d1_value, d1[k,] %>% unlist %>% as.character) %>% length >= (length(dr_d1_value)-2)){
            out1 <- c(out1, k)
            break
          }
        }
        for(k in 1:nrow(d2)){
          if(intersect(dr_d2_value, d2[k,] %>% unlist %>% as.character) %>% length >= (length(dr_d2_value)-2)){
            out2 <- c(out2, k)
            break
          }
        }
      }
      
      # 上のFor文で拾ったデータの行の要素を調べ，d1とd2で比較し，要素をデータフレームに記録する
      for(i in 1:nrow(temp$differentrows)){
        d1diff <- d1[out1[i],] %>% unlist
        d2diff <- d2[out2[i],] %>% unlist
        
        d1_diff_value <- setdiff(d1diff, d2diff) %>% paste(collapse=",") # 複数要素異なる場合には，コンマ切りで記録
        d2_diff_value <- setdiff(d2diff, d1diff) %>% paste(collapse=",")
        
        diff_df <- rbind(diff_df, c(out1[i], d1_diff_value, out2[i], d2_diff_value))
      }
      
      diff_df <- as.data.frame(diff_df)
      colnames(diff_df) <- c("d1_row", "d1_difvalue", "d2_row", "d2_difvalue")
    } else {diff_df <- NULL}
    
    
    
    rem_d1 <- c()
    rem_d2 <- c()
    if(nrow(temp$removed_d1) > 0){
      # compareTextfilesの出力のうち，削除された行(removed)を拾う
      for(i in 1:nrow(temp$removed_d1)){
        rm_d1_value <- temp$removed_d1[i, 2] %>% str_split(",") %>% unlist %>% .[.!=""]
        
        # データの行とsdiffの返り値の間の共通の要素の数がsdiffの返り値の要素数より2小さい値より大きいとき，その行を記録する
        # 変な処理ではあるが，何故かsdiffの要素数より短くなることがあるので，-2している
        for(k in 1:nrow(d1)){
          if(intersect(rm_d1_value, d1[k,] %>% unlist %>% as.character) %>% length >= (length(rm_d1_value)-2)){
            rem_d1 <- c(rem_d1, k)
            break
          }
        }
      }
    } else {rem_d1 <- NULL}
    
    if(temp$removed_d2 %>% nrow > 0){
      for(i in 1:nrow(temp$removed_d2)){
        rm_d2_value <- temp$removed_d2[i, 2] %>% str_split(",") %>% unlist %>% .[.!=""]
        
        # データの行とsdiffの返り値の間の共通の要素の数がsdiffの返り値の要素数より2小さい値より大きいとき，その行を記録する
        # 変な処理ではあるが，何故かsdiffの要素数より短くなることがあるので，-2している
        for(k in 1:nrow(d2)){
          if(intersect(rm_d2_value, d2[k,] %>% unlist %>% as.character) %>% length >= (length(rm_d2_value)-2)){
            rem_d2 <- c(rem_d2, k)
            break
          }
        }
      }} else {rem_d2 <- NULL}
    
    out <- list(
      difference_in_two_df = diff_df,
      removed_d1 = rem_d1,
      removed_d2 = rem_d2
    )
  } else {
    out <- NULL
  }
  return(out)
}

# Inputの形によって出力を変更する関数
inputControl <- function(path, nsheet){
  if (is.null(path)){
    "ファイルを選択してください"
  } else if (str_detect(path, ".xls")) {
    tryCatch({
      read_excel(
        path,
        sheet = nsheet,
        col_names = F,
        col_types = "text"
      )
    },
    error = function(e) {
      "シートが正しく選択されていません"
    }, silent = F)
  } else if (str_detect(path, ".csv")) {
    read_csv(path,
             show_col_types = FALSE,
             col_names = F,
             col_types = "c")
  } else if (str_detect(path, ".tsv")) {
    read_tsv(path,
             show_col_types = FALSE,
             col_names = F,
             col_types = "c")
  } else {
    "エクセルファイル，CSVファイル，TSVファイル以外が選択されています"
  }
}
