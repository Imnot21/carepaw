import zipfile,os,sys
docxml, out = sys.argv[1], sys.argv[2]
src=zipfile.ZipFile('C:/Users/six6six/Desktop/LARAMAGANDA.docx')
names=[i.filename for i in src.infolist()]
extra=[f'word/media/{n}' for n in os.listdir('ed/word/media') if f'word/media/{n}' not in names]
with zipfile.ZipFile(out,'w',zipfile.ZIP_DEFLATED) as z:
    for n in names+extra:
        if n=='word/document.xml': z.write(docxml,n)
        else: z.write(os.path.join('ed',n),n)
print(out, len(extra),'new media')
