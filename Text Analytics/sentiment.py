import csv
import nltk
import re
import string
import gensim
from sentiment_module import sentiment
import pandas as pd

inp = open( 'jokes.csv', 'r', newline='' )
reader = csv.reader( inp )
header1 = reader.__next__()

# creating the list of jokes 
jokes = []
for i in reader:
    jokes.append(i)

inp = open( 'good_jokes.csv', 'r', newline='' )
reader = csv.reader( inp )
header2 = reader.__next__()

# creating the list of good jokes 
good_jokes = []
for i in reader:
    good_jokes.append(i)
    
inp = open( 'bad_jokes.csv', 'r', newline='' )
reader = csv.reader( inp )
header3 = reader.__next__()

# creating the list of bad jokes 
bad_jokes = []
for i in reader:
    bad_jokes.append(i)
    
# Creating dataframes
joke = pd.DataFrame(jokes,columns=header1)
goodjokes=pd.DataFrame(good_jokes,columns=['joke_id','N_Obs','Median','Type'])
badjokes=pd.DataFrame(bad_jokes,columns=['joke_id','N_Obs','Median','Type'])