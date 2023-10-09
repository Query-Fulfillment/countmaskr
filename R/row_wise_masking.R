#' Function to perform element-wse suppression of list of suppressed vectors
#'
#' @param list list of suppressed vectors that requires element-wise suprression
#'
#' @return
#' @export
#'
#' @examples
rowwise_suppression <- function(list) {
  for (i in seq_along(list[[1]])) {
    if (sum(sapply(list, function(v) grepl("<", v[i]))) == 1) {
      small_cell_index <- which(sapply(list, function(v) grepl("<", v[i])))


      secondary_cell <- min(as.numeric(sapply(list[-small_cell_index], function(v) v[i])), na.rm = T)


      secondary_cell_index <- which(suppressWarnings(as.numeric(sapply(list, function(v) v[i]))) == secondary_cell)


      list[[secondary_cell_index]][i] <- sub(
        list[[secondary_cell_index]][i],
        paste0("<", 10 * ceiling(secondary_cell) / 10),
        list[[secondary_cell_index]][i]
      )
    }
  }
  return(list)
}
