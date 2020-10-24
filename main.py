import os
import pickle
import time
import matplotlib.pyplot as plt
import pandas as pd
import plotly.express as px
from pywikiapi import wikipedia
from typing import List, Dict
from wordcloud import WordCloud, STOPWORDS


def save_script(module):
    """
    Save all script files on module directory
    :param module: A dict returned from Wikimedia API
    """
    if not os.path.exists("module"):
        os.mkdir("module")
    with open(f"module/{module.title.replace('/', '_')}_{module.pageid}.lua", "w") as file:
        file.write(module.wikitext)


def save_metainfo(pages: List[Dict], pages_error: List[int]):
    """
    Save a python object with pickle module to a file
    :param pages: A list of page info
    :param pages_error: A list of pageid where errors occurred
    """
    with open("pages.dat", "wb") as f:
        pickle.dump(pages, f)
    with open("pages_error.dat", "wb") as f:
        pickle.dump(pages_error, f)


def get_info_from_files() -> List[Dict[str, int]]:
    """
    Get information size and name from saved lua modules
    :return: A list with title and size of lua module
    """
    arr = []
    for i in os.listdir("module"):
        data = {'title': i, 'size': os.path.getsize(f"module/{i}")}
        arr.append(data)
    return arr


def get_pages() -> [List[Dict], List[int]]:
    """
    Get all lua modules from the Wiki, exclude doc pages
    :return: A list of page info and list of pageids where errors occurred
    """
    site = wikipedia('en')
    pages = []
    modules_names = []
    error_pages = []
    # Asks 500 (max) per iteration lua modules pages for api
    for r in site.query(list='allpages', apnamespace="828", aplimit="max"):
        # Iterates in the results
        for page in r.allpages:
            # Check if a documentation file
            if "/doc" not in page.title and "testcase" not in page.title and "Module:User:" not in page.title \
                    and page.title.split("/")[0] not in modules_names:
                try:
                    # Not search submodules
                    modules_names.append(page.title.split("/")[0])
                    # Get module lua content
                    for module in site.iterate("parse", pageid=page.pageid, prop="wikitext"):
                        data = {'title': module.title, 'pageid': module.pageid, 'size': len(module.wikitext)}
                        pages.append(data)
                        print(f"{module.title} successfully added")
                        save_script(module)
                        # Wait 1 second
                        time.sleep(1)
                except:
                    # Saves pages that have errors
                    error_pages.append(page.pageid)
                    print(f"An error occurred while downloading the module: {module.title}")
    return pages, error_pages


def make_graphics(pages):
    """
    Save histogram and word cloud
    :param pages: A list of page info
    """
    df = pd.DataFrame.from_dict(pages)
    stopwords = set(STOPWORDS)
    stopwords.update(["module", "Module", "ISO"])
    px.histogram(df, x='size', labels={'x': "lua module size (bytes)", 'y': "Count Files"}).write_html(
        "results/histogram.html")
    words = WordCloud(background_color='white',
                      width=1024,
                      height=512,
                      stopwords=stopwords
                      ).generate(' '.join(df['title']))
    plt.imshow(words)
    plt.axis('off')
    plt.savefig('results/World_Cloud_module_name.png')


# Main
if __name__ == '__main__':
    pages = []
    if os.path.isfile("pages.dat"):
        with open("pages.dat", "rb") as file:
            pages = pickle.load(file)
    elif os.path.isdir("module"):
        pages = get_info_from_files()
    else:
        pages, pages_error = get_pages()
        save_metainfo(pages, pages_error)
    make_graphics(pages)
