instagram scraper
--

## Getting Started

### requirement

using docker:

```
docker build . -t instagram_scraper
docker run -it -v (pwd):/usr/workspace instagram_scraper bash
```

or 

local machine(mac):

```
brew install chromedriver
pip install -r requirements.txt
```

### run

```
python scraper.py -n 100 -t ラーメン -o scraped_data
```
