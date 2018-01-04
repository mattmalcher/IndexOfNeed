
file2 <- 'http://www.nomisweb.co.uk/api/v01/help'  

rsdmxAgent <- paste("rsdmx/", as.character(packageVersion("rsdmx")), 
                    sep = "")

h <- RCurl::basicHeaderGatherer()

content2 <- RCurl::getURL(file2, httpheader = list(`User-Agent` = rsdmxAgent), 
                         ssl.verifypeer=TRUE, .encoding = "UTF-8", headerfunction = h$update)

if (as.numeric(h$value()["status"]) >= 400) {
  stop("HTTP request failed with status: ", h$value()["status"], 
       " ", h$value()["statusMessage"])
  
  
  
#------------------------------------------------------------------------------------------------  

file <- 'https://www.nomisweb.co.uk/api/v01/help'  

rsdmxAgent <- paste("rsdmx/", as.character(packageVersion("rsdmx")), 
                    sep = "")

req_content <- httr::GET(file, add_headers(`User-Agent` = rsdmxAgent))
content<-  content( req_content,"text")

if (httr::http_error(req_content)) {
  stop("HTTP request failed with status: ",httr::http_status(req_content)])
  