# Author: Robert J. Hijmans
# Date :  June 2008
# Version 1.0
# Licence GPL v3


if (!isGeneric("reclassify")) {
	setGeneric("reclassify", function(x, rcl, ...)
		standardGeneric("reclassify"))
}	


setMethod('reclassify', signature(x='Raster', rcl='ANY'), 
function(x, rcl, filename='', include.lowest=FALSE, right=TRUE, ...) {
	
	filename <- trim(filename)

	if ( is.null(dim(rcl)) ) { 
		rcl <- matrix(rcl, ncol=3, byrow=TRUE) 
	} else if ( dim(rcl)[2] == 1 ) { 
		rcl <- matrix(rcl, ncol=3, byrow=TRUE) 
	} else if (is.data.frame(rcl)) {
		rcl <- as.matrix(rcl)
	}
	
	nc <- ncol(rcl)
	if ( nc != 3 ) { 
		if (nc == 2) {
			colnames(rcl) <- c("Is", "Becomes")	
			if (getOption('verbose')) { print(rcl)  }
			rcl <- cbind(rcl[,1], rcl)
			right <- NA
		} else {
			stop('rcl must have 2 or 3 columns') 
		}
	} else {
		colnames(rcl) <- c("From", "To", "Becomes")	
		if (getOption('verbose')) { print(rcl)  }
	}

	
	hasNA <- FALSE
	onlyNA <- FALSE
	valNA <- NA
#	if (nc == 3) {
	i <- which(is.na(rcl[, 1]) | is.na(rcl[, 2]))
	if (length(i) > 0) {
		valNA <- rcl[i[1],3]
		hasNA <- TRUE
		rcl <- rcl[-i, ,drop=FALSE]
	}

#	} else {
#		i <- which(is.na(rcl[, 1]))
#		if (length(i) > 1) {
#			valNA <- rcl[i[1], 2]
#			hasNA <- TRUE
#			rcl <- rcl[-i, ,drop=FALSE]
#		}
#	}

	if (dim(rcl)[1] == 0) {
		if (hasNA) {
			onlyNA <- TRUE
		} 
	} else {
		stopifnot(all(rcl[,2] >= rcl[,1]))
	}
	
	

	nl <- nlayers(x)
	if (nl == 1) { 
		out <- raster(x)
	} else { 
		out <- brick(x, values=FALSE) 
	}

	include.lowest <- as.integer(include.lowest)
	right <- as.integer(right)
	#hasNA <- as.integer(hasNA)
	onlyNA <- as.integer(onlyNA)
	valNA <- as.double(valNA)
	
	if (nc == 2) {
		rcl <- rcl[ , 2:3, drop=FALSE]
	}
	
	if (canProcessInMemory(out)) {
		out <- setValues(out, .Call('_reclass', values(x), rcl, include.lowest, right, onlyNA, valNA, NAOK=TRUE, PACKAGE='raster'))
		if ( filename != "" ) { 
			out <- writeRaster(out, filename=filename, ...) 
		}
		return(out)
				
	} else {
		
		tr <- blockSize(out)
		pb <- pbCreate(tr$n, label='reclassify', ...)
		out <- writeStart(out, filename=filename, ...)
		
		for (i in 1:tr$n) {
			vals <- getValues( x, row=tr$row[i], nrows=tr$nrows[i] )
			vals <- .Call('_reclass', vals, rcl, include.lowest, right, onlyNA, valNA, NAOK=TRUE, PACKAGE='raster')
			if (nl > 1) {
				vals <- matrix(vals, ncol=nl)
			}
			out <- writeValues(out, vals, tr$row[i])
			pbStep(pb, i)
		}
		out <- writeStop(out)
		pbClose(pb)
		
		return(out)
	}
}
)


		
