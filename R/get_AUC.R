#' Get confusion matrix
#'
#' @param r raster with binary predictions.
#' @param df data.frame with locations (long, lat) and observed value (0, 1).
confusion <- function(r, df) {
	p <- df[, 3]
	if (!all(unique(p) %in% c(0, 1))) {
		stop("Third column of the data.frame should be presence-absence")
	}
	x <- df[, 1]
	y <- df[, 2]
	vals <- raster::extract(r, cbind(x, y))
	pos <- which(p == 1)
	neg <- which(p == 0)
	tp <- sum(vals[pos] == p[pos])
	fp <- sum(vals[pos] != p[pos])
	tn <- sum(vals[neg] == p[neg])
	fn <- sum(vals[neg] != p[neg])
	ans <- data.frame(obs.presence = rep(NA, 2), 
		obs.absence = rep(NA, 2))
	rownames(ans) <- c("pred.presence", "pred.absence")
	ans[1, 1] <- tp
	ans[1, 2] <- fp
	ans[2, 1] <- fn
	ans[2, 2] <- tn
	spec <- ans[1, 1] / rowSums(ans)[1]
	sens <- ans[2, 2] / rowSums(ans)[2]
	return(list(confusion.table = ans, 
				specificity = as.vector(spec), 
				sensitivity = as.vector(sens)))
}
#' Get AUC
#' 
#' @inherit confusion
#' @param th threshold to apply to binarize suitability.
AUC <- function(x, y) {
	ans <- c()
	for (i in seq(1, length(x) - 1)) {
		rect <- (x[i + 1] - x[i]) * y[i]
		tri <- (x[i + 1] - x[i]) * (y[i + 1] - y[i]) / 2
		ans <- append(ans, rect + tri)
	}
	return(sum(ans))
}
#' Get AUROC
#' 
#' @inherit confusion
#' @param th threshold to apply to binarize suitability.
AUROC <- function(r, df, th = 10^seq(-3, 0, length.out = 25), plot = TRUE) {
	ans <- c()
	for (x in th) {
		r_tmp <- r
		r_tmp[r_tmp < x] <- 0
		r_tmp[r_tmp >= x] <- 1
		conf <- confusion(r_tmp, df)
		spec <- conf$specificity
		sens <- conf$sensitivity
		ans <- rbind(ans, cbind(x, spec, sens))
	}
	ans <- rbind(ans, cbind(1, 0, 1))
	ans <- rbind(ans, cbind(0, 1, 0))
	colnames(ans) <- c("threshold", "specificity", "sensitivity")
	ans <- ans[order(ans[, "sensitivity"]), ]
	auc <- AUC(1 - ans[, "specificity"], ans[, "sensitivity"])
	if (plot) {
		plot(1 - ans[, "specificity"], 
			ans[, "sensitivity"],
			pch = 20,
			type = "b",
			frame = FALSE,
			xlab = "1 - specificity",
			ylab = "sensitivity",
			xlim = c(0, 1),
			ylim = c(0, 1),
			main = paste("AUC =", round(auc, 2)))
		abline(0, 1, lt = 2)
	}
	return(list(AUROC = ans, AUC = auc))
}
