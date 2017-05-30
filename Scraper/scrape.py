from lxml import html
import requests
import re
from bs4 import BeautifulSoup
MYFILE = "links.txt"

def secondToLast(text, pattern):
    return text.rfind(pattern, 0, text.rfind(pattern))

def getLinksToFile(MYFILE):
    mS = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'June', 'July', 'Aug', 'Sept', 'Oct', 'Nov', 'Dec'];
    urlStr = "https://www.nationaldaycalendar.com/"
    File = open(MYFILE, "w")
    links = []
    for x in mS:
        page = requests.get(urlStr + x)
        soup = BeautifulSoup(page.text, "lxml")
        #print(soup.prettify())
        links = []
        for a in soup.find_all('a', href=True):
            links.append(a['href'])
            print(a)
        File.write(str(links))

def splitArray(MYFILE):
    links = []
    stri = ""
    with open(MYFILE, 'r') as myfile:
        stri = myfile.read()
    links = stri.split(",")
    return links
def getData(links):
    #links gets passed in as a text file with an array of links inside. sadly it comes
    #as a string, not an array, so a little more parsing has to be done
    #also sets up another file to save all the data to once the program is done running
    file = open("alldata.txt", "w")
    articleLink = []
    allDATA = {}
    month = False
    #wacky fix for indentation
    for i in range(1):
        for link in links:
            #chop extraneous chars    eg 'link' deletes the quotes
            link = link[2:-1]
            #get month and day from link
            monthday = ""
            monthday = link[secondToLast(link, '-' )+1:-1].replace("-", " ")
            #if monthday key doesnt exist create it as an array
            if(monthday not in allDATA):
                #if "may" not in monthday or month == False:
                    #print("SKIP :", monthday)
                   # continue
                 #"in" in monthday or "the" in monthday
                #make sure monthday isnt something like, "first monday in january"
                if not re.match(r"(january|february|march|april|may|june|july|august|september|october|november|december) [0-9]{1,2}$", monthday):
                    print("BAD DATA:" , monthday[-30:] ,link[-30:])
                    continue
                else:
                    allDATA[monthday] = []
            #get page data
            page = requests.get(link)
            soup = BeautifulSoup(page.text, "lxml")
            soup.img.decompose()
            #find all tags with class post content, there should only be 1
            for a in soup.findAll('div', {"class" :'post-content entry-content'}):
                #find all p tags 
                for p in soup.findAll('p'):
                    #every page that is a day contains that text, this check gets rid of bad links    eg home
                    if(p.getText() == 'There are over 1,200 national days. Don’t miss a single one. Celebrate Every Day with National Day Calendar!'):
                        #there is only 1 h3 tag per page, it is the title of the day
                        try:
                            title = a.find('h3').getText()
                            #if the title isnt grabbed, see if its the next h3, otherwise, skip item
                            #titles seem to change format a little bit, this covers 80-90% of the cases
                            if(len(title) < 2):
                                title = a.findAll('h3')[1].getText()
                            if(len(title) < 2):
                                print("Skipping item: Title broken")
                                continue
                            articleLink.append(title.strip())
                            title = ""
                            #this is all the content of the article, replace gets rid of some stuff we dont need (STILL HAS \n) and change unicode chars
                            articleLink.append("".join(a.findAll(text=True)).replace("\xa0", " ").replace("\u2122", " tm").replace("\xfb", "u").replace("\xf6", "o").replace("(adsbygoogle = window.adsbygoogle || []).push({});", ""))
                        except Exception as e:
                            print(e)
                            print("BAD DATA: something broke at", link)
                            #if something goes wrong, skip item and dont append to list
                            continue
                        #append all data to monthday key in alldata
                        allDATA[monthday].append(articleLink)
                        articleLink = []
            try:
                print(monthday, allDATA[monthday][len(allDATA[monthday])-1][0], "..."+link[-30:-1])
            except IndexError:
                continue
    #finally write all to file
    file.seek(0)
    file.truncate()
    file.write(remove_non_ascii_2(remove_non_ascii_1(str(allDATA).replace("\u2013", "-").replace("\u2019", "'").replace("\u201c", '"').replace("\u201d", '"').replace("\u2018", "'"))))

def remove_non_ascii_1(text):
    return ''.join([i if ord(i) < 128 else ' ' for i in text])
def remove_non_ascii_2(text):
    re.sub(r'[^\x00-\x7F]+',' ', text)

def main():
 #   getLinksToFile(MYFILE)
    links = splitArray(MYFILE)
    articles = getData(links)
    

    
main()
