# Author: Robert J. Hijmans, r.hijmans@gmail.com
# Date :  June 2008
# Version 0.9
# Licence GPL v3


if (!isGeneric("cover")) {
	setGeneric("cover", function(x, y, ...)
		standardGeneric("cover"))
}	

setMethod('cover', signature(x='RasterStackBrick', y='Raster'), 
	function(x, y, ..., filename='', format, datatype, overwrite, progress){ 

	rasters <- .makeRasterList(x, y, ..., unstack=FALSE)
	nl <- sapply(rasters, nlayers)
	un <- unique(nl)
	if (length(un) > 3) {
		stop('number of layers does not match')
	} else if (length(un) == 2 & min(un) != 1) {
		stop('number of layers does not match')
	} else if (nl[1] != max(un)) {
		stop('number of layers of the first object must be the highest') # need to remove this constraint
	}
	
	outRaster <- brick(x, values=FALSE)

	if (missing(format)) { format <- .filetype() } 
	if (missing(overwrite)) { overwrite <- .overwrite() }
	if (missing(progress)) { progress <- .progress() }
	if (missing(datatype)) { datatype <- 'FLT4S' }
	
	filename <- trim(filename )

	if ( canProcessInMemory(x, sum(nl)+nl[1])) {

		v <- getValues( rasters[[1]] )
		v2 <- v
		for (j in 2:length(rasters)) {
			v2[] <- getValues( rasters[[j]] )
			v[is.na(v)] <- v2[is.na(v)]
		}	
		outRaster <- setValues(outRaster, v)
		if (filename != '') {
			outRaster <- writeRaster(outRaster, filename=filename, format=format, datatype=datatype, overwrite=overwrite, progress=progress )
		}
		
	} else {
	
		if (filename == '') { filename <- rasterTmpFile() }
		outRaster <- writeStart(outRaster, filename=filename, format=format, datatype=datatype, overwrite=overwrite, progress=progress )
		
		tr <- blockSize(outRaster, length(rasters))
		pb <- pbCreate(tr$n, type=.progress())
		for (i in 1:tr$n) {
			v <- getValues( rasters[[1]], row=tr$row[i], nrows=tr$nrows[i] )
			v2 <- v
			for (j in 2:length(rasters)) {
				v2[] <- getValues(rasters[[j]], row=tr$row[i], nrows=tr$nrows[i])
				v[is.na(v), ] <- v2[is.na(v), ] 
			}	
			outRaster <- writeValues(outRaster, v, tr$row[i])
			pbStep(pb, i) 
		}
		pbClose(pb)
		outRaster <- writeStop(outRaster)
	}
	return(outRaster)
}
)
