"""Full redline of LARAMAGANDA.docx (round 1 + round 2).

Usage: python redline2.py <unpacked dir> <png dir>
Writes word/document.xml with page-number placeholders ##_cpX## and
clean.xml (struck text removed) next to it for page counting.
"""
import os
import re
import shutil
import struct
import sys

SRC = open(os.path.join(os.path.dirname(__file__), 'redline.py'), encoding='utf8').read()
exec(SRC.split('# ---------------- Section 3')[0])  # helpers + P, orig, after, log

PNG_DIR = sys.argv[2]
REL_PATH = f'{D}/word/_rels/document.xml.rels'
rels = open(REL_PATH, encoding='utf8').read()

# ---------------- extra helpers ----------------
_bm = [9000]


def bm_xml(name):
    _bm[0] += 1
    i = _bm[0]
    return f'<w:bookmarkStart w:id="{i}" w:name="{name}"/><w:bookmarkEnd w:id="{i}"/>'


def bm(i, name, expect):
    assert ptext(orig[i]).strip().startswith(expect) or expect in ptext(orig[i]), (i, expect, ptext(orig[i])[:80])
    P[i] = P[i][:-len('</w:p>')] + bm_xml(name) + '</w:p>'


def with_bm(pxml, name):
    return pxml[:-len('</w:p>')] + bm_xml(name) + '</w:p>'


def put(i, *paras):
    after.setdefault(i, []).extend(paras)


def ppr_of(i):
    m = re.search(r'<w:pPr>.*?</w:pPr>', orig[i], flags=re.S)
    return re.sub(r'<w:pageBreakBefore/>', '', m.group(0) if m else '<w:pPr></w:pPr>')


def rpr_of(i):
    m = re.search(r'<w:r(?: [^>]*)?>(<w:rPr>.*?</w:rPr>)?', orig[i], flags=re.S)
    r = (m.group(1) or '') if m else ''
    return re.sub(r'<w:highlight [^>]*/>', '', r)


def with_tabs(ppr, tabs):
    ppr = re.sub(r'<w:tabs>.*?</w:tabs>', '', ppr, flags=re.S)
    tx = '<w:tabs>' + ''.join(f'<w:tab w:val="{v}"{" w:leader=%s" % chr(34) + l + chr(34) if l else ""} w:pos="{p}"/>' for v, p, l in tabs) + '</w:tabs>'
    for nxt in ('<w:suppressAutoHyphens', '<w:spacing', '<w:ind', '<w:jc', '<w:rPr', '</w:pPr>'):
        k = ppr.find(nxt)
        if k >= 0:
            return ppr[:k] + tx + ppr[k:]
    return ppr


RIGHT = 9350


def entry(template_i, parts, name, numbered=False):
    """Green list entry: parts joined by tabs, then a page field."""
    tabs = ([('left', 720, '')] if numbered else []) + [('right', RIGHT, 'dot')]
    ppr = with_tabs(ppr_of(template_i), tabs)
    g = style(rpr_of(template_i), GREEN, False)
    runs = []
    for k, part in enumerate(parts):
        runs.append(f'<w:r>{g}{"<w:tab/>" if k else ""}{t(part)}</w:r>')
    runs.append(f'<w:r>{g}<w:tab/></w:r><w:r>{g}{t("§BM:" + name + "§")}</w:r>')
    return f'<w:p w14:paraId="{new_id()}" w14:textId="77777777">{ppr}{"".join(runs)}</w:p>'


def green_para(template_i, text, color=GREEN, ppr=None):
    ppr = ppr if ppr is not None else ppr_of(template_i)
    r = style(rpr_of(template_i), color, False)
    return f'<w:p w14:paraId="{new_id()}" w14:textId="77777777">{ppr}<w:r>{r}{t(text)}</w:r></w:p>'


_doc = [5000]
used_docpr = set(re.findall(r'<wp:docPr id="(\d+)"', xml))


def image_para(png_name, media_name, rid):
    src = os.path.join(PNG_DIR, png_name)
    shutil.copyfile(src, f'{D}/word/media/{media_name}')
    global rels
    if f'Id="{rid}"' not in rels:
        rels = rels.replace('</Relationships>',
                            f'<Relationship Id="{rid}" Type="http://schemas.openxmlformats.org/officeDocument/2006/relationships/image" Target="media/{media_name}"/></Relationships>')
    with open(src, 'rb') as f:
        f.read(16)
        w, h = struct.unpack('>II', f.read(8))
    cx = 5943600
    cy = int(cx * h / w)
    while str(_doc[0]) in used_docpr:
        _doc[0] += 1
    did = _doc[0]
    _doc[0] += 1
    a = 'xmlns:a="http://schemas.openxmlformats.org/drawingml/2006/main"'
    drawing = (
        f'<w:drawing><wp:inline distT="0" distB="0" distL="0" distR="0"><wp:extent cx="{cx}" cy="{cy}"/>'
        f'<wp:effectExtent l="0" t="0" r="0" b="0"/><wp:docPr id="{did}" name="Picture {did}"/>'
        f'<wp:cNvGraphicFramePr><a:graphicFrameLocks {a} noChangeAspect="1"/></wp:cNvGraphicFramePr>'
        f'<a:graphic {a}><a:graphicData uri="http://schemas.openxmlformats.org/drawingml/2006/picture">'
        f'<pic:pic xmlns:pic="http://schemas.openxmlformats.org/drawingml/2006/picture">'
        f'<pic:nvPicPr><pic:cNvPr id="{did}" name="{media_name}"/><pic:cNvPicPr/></pic:nvPicPr>'
        f'<pic:blipFill><a:blip r:embed="{rid}"/><a:stretch><a:fillRect/></a:stretch></pic:blipFill>'
        f'<pic:spPr><a:xfrm><a:off x="0" y="0"/><a:ext cx="{cx}" cy="{cy}"/></a:xfrm>'
        f'<a:prstGeom prst="rect"><a:avLst/></a:prstGeom></pic:spPr></pic:pic></a:graphicData></a:graphic>'
        f'</wp:inline></w:drawing>')
    ppr = '<w:pPr><w:spacing w:before="240" w:after="120" w:line="240" w:lineRule="auto"/><w:jc w:val="center"/></w:pPr>'
    return f'<w:p w14:paraId="{new_id()}" w14:textId="77777777">{ppr}<w:r>{drawing}</w:r></w:p>'


def fix_num(i, name, expect):
    """Strike the old page number at the end of a TOC line, add a green field."""
    text = ptext(P[i])
    assert expect in text, (i, expect, text)
    m = re.search(r'(\d+)\s*$', text)
    P[i] = apply(P[i], [(m.start(1), m.end(1), '§BM:' + name + '§')])
    log.append(f'P{i}: page "{m.group(1)}" -> field {name}')


# ======================= Section 3: layout =======================
# --- Table of Contents, Chapter 1 (item 5) ---
fix_num(51, '_cpCh1', 'Introduction')
fix_num(52, '_cpBg', 'Background of the Project')
strike_all(53, 'Objectives of the Project')
fix_num(54, '_cpClient', 'Client Profile')
strike_all(55, 'Scope')
put(55, *[entry(52, [n], k) for n, k in [
    ('Existing Business Process', '_cpEbp'), ('Existing System Analysis', '_cpEsa'),
    ('Business Process Analysis', '_cpBpa'), ('Requirements Gathering', '_cpRg'),
    ('Needs Assessment', '_cpNa'), ('Project Objectives', '_cpPo'),
    ('Scope and Delimitations', '_cpSd'), ('Project Significance', '_cpPs'),
    ('Conceptual Framework', '_cpCf'), ('Project Framework', '_cpPf'),
    ('Definition of Terms', '_cpDt')]])
# --- Table of Contents, Chapter 2 (item 5) ---
rep(56, 'LITERATURE AND STUDIES', 'LITERATURE, STUDIES, AND TECHNOLOGIES', expect='CHAPTER 2')
put(56, entry(57, ['Related Literature'], '_cpRl'))
fix_num(57, '_cpFl', 'Foreign Literature')
fix_num(58, '_cpLl', 'Local Literature')
put(58, entry(59, ['Related Studies'], '_cpRs'))
fix_num(59, '_cpFs', 'Foreign Studies')
fix_num(60, '_cpLs', 'Local Studies')
put(60, *[entry(60, [n], k) for n, k in [
    ('Related Technologies', '_cpRt'), ('Software Development Methodologies', '_cpSdm'),
    ('Software Quality Standards', '_cpSqs'), ('Synthesis', '_cpSyn'), ('Project Gap', '_cpGap')]])
# --- Table of Contents, Chapter 3 ---
rep(61, 'TECHNICAL BACKGROUND', 'PROJECT ANALYSIS AND DESIGN', expect='CHAPTER 3')
for i, e in [(62, 'Research Approach'), (63, 'Methodology'),
             (64, 'Planning Phase'), (65, 'Requirement Elicitation Phase')]:
    strike_all(i, e)
put(65, entry(63, ['System Requirements'], '_cpSr'), entry(63, ['Use Case Diagram'], '_cpUc'))
fix_num(66, '_cpSdes', 'System Design')
put(66, *[entry(66, [n], k) for n, k in [
    ('Context Diagram', '_cpCtxH'), ('Level 1 Data Flow Diagram', '_cpDfdH'),
    ('Entity-Relationship Diagram', '_cpErdH'), ('System Architecture Diagram', '_cpArchH')]])

# --- List of Tables ---
for i, e in [(80, 'Project Scope Table'), (81, 'Data Gathering Tools Table'),
             (82, 'Functional and Non-Functional Requirements Table')]:
    strike_all(i, e)
tables = ['Gap Analysis of CAREPAW', 'System Requirements', 'Functional Requirements',
          'Non-Functional Requirements'] + [
    f'Data Dictionary – {n}' for n in
    ['users', 'pets', 'appointments', 'queueEntries', 'medicalRecords', 'inventoryItems',
     'inventoryBatches', 'inventoryTransactions', 'scanRecords', 'notifications',
     'notificationPreferences', 'auditLogs']]
put(82, *[entry(80, [str(n), name], f'_cpT{n}', numbered=True) for n, name in enumerate(tables, 1)])

# --- List of Figures ---
for i, e in [(86, 'Agile System Development Life Cycle'), (87, 'Gantt'),
             (88, 'Use Case Diagram'), (89, 'Context Diagram'),
             (90, 'Level 1 Data Flow Diagram'), (91, 'User Interface Mockups')]:
    strike_all(i, e)
figures = ['Organizational Structure of DocMyk’s PILA VET HUB',
           'Existing Workflow of DocMyk’s PILA VET HUB',
           'Conceptual Framework of CarePaw', 'Waterfall Model of CarePaw',
           'Waterfall Model', 'Use Case Diagram of CarePaw', 'Context Diagram of CarePaw',
           'Level 1 Data Flow Diagram of CarePaw', 'Entity-Relationship Diagram of CarePaw',
           'System Architecture Diagram of CarePaw']
put(91, *[entry(86, [str(n), name], f'_cpF{n}', numbered=True) for n, name in enumerate(figures, 1)])

# --- Figure captions ---
assert ptext(P[430]).strip() == 'Figure'
ins(430, 'Figure', ' 6 Use Case Diagram of CarePaw')
assert ptext(P[436]).strip() == 'Figure'
ins(436, 'Figure ', '9 Entity-Relationship Diagram of CarePaw')

# --- Data dictionary table numbers and the leftover note ---
dd = [(438, 'users'), (440, 'pets'), (444, 'appointments'), (447, 'queueEntries'),
      (451, 'medicalRecords'), (455, 'inventoryItems'), (459, 'inventoryBatches'),
      (462, 'inventoryTransactions'), (465, 'scanRecords'), (469, 'notifications'),
      (472, 'notificationPreferences'), (475, 'auditLogs')]
for n, (i, name) in enumerate(dd):
    old = f'3.{9 + n}'
    rep(i, old, str(5 + n), expect=f'Table {old}. Data Dictionary')
    assert name in ptext(P[i]), (i, name)
    bm(i, f'_cpT{5 + n}', 'Table')
rep(438, ' (Mali table number hanggang baba)', '')

# --- Missing "Mobile-Based" in the Related Technologies title ---
ins(320, 'The proposed CarePaw: A ', 'Mobile-Based ')

# --- Context Diagram and Level 1 DFD (item 3) ---
assert ptext(orig[433]).startswith('The system design presents')
assert ptext(orig[434]).strip() == 'Entity-Relationship Diagram'
put(433,
    with_bm(green_para(434, 'Context Diagram'), '_cpCtxH'),
    image_para('figure-3.3-context.png', 'image24.png', 'rId900'),
    with_bm(green_para(436, 'Figure 7 Context Diagram of CarePaw'), '_cpF7'),
    green_para(433, 'Figure 7 presents the context diagram of CarePaw. It shows the whole system as one process '
               'and the information it exchanges with its external entities: the pet owner, the clinic '
               'owner/admin, and the Gemini AI model. Pet owners send account details, pet information, and '
               'appointment requests and cancellations, and receive appointment status, queue status, pet health '
               'records, and notifications. The clinic owner/admin sends appointment approvals and updates, '
               'check-in and queue updates, health record details, medicine details, and scanned images, and '
               'receives appointment requests, the patient queue, pet profiles and health records, inventory '
               'information, recognized medicine details, and notifications. The Gemini AI model receives the '
               'scanned image of a medicine box or receipt and returns the recognized medicine details.'),
    with_bm(green_para(434, 'Level 1 Data Flow Diagram'), '_cpDfdH'),
    image_para('figure-3.4-dfd1.png', 'image25.png', 'rId901'),
    with_bm(green_para(436, 'Figure 8 Level 1 Data Flow Diagram of CarePaw'), '_cpF8'),
    green_para(433, 'Figure 8 presents the Level 1 Data Flow Diagram of CarePaw. It divides the system into eight '
               'processes: user authentication, pet profile management, appointment management, queue '
               'monitoring, animal health records, medicine inventory, scanning and recognition, and '
               'notifications. It shows how data moves between these processes, the pet owner, the clinic '
               'owner/admin, the Gemini AI model, and the data stores for users, pets, appointments, queue '
               'entries, medical records, inventory, scan records, and notifications.'),
    )

# --- System Architecture Diagram: new picture without Cloud Messaging (item 2) ---
put(478, green_para(478, 'Delete the old diagram below. It still shows Firebase Cloud Messaging and Cloud '
                         'Functions, which the system does not use. The updated diagram follows it.', color=RED))
put(479,
    image_para('figure-3.10-arch.png', 'image26.png', 'rId902'),
    with_bm(green_para(436, 'Figure 10 System Architecture Diagram of CarePaw'), '_cpF10'))

# --- Duplicate Table 4 picture (item 4): drop the second copy ---
dup = [m.group(0) for m in re.finditer(r'<w:r(?: [^>]*)?>(?:(?!</w:r>).)*?<w:drawing>.*?</w:drawing>.*?</w:r>', P[425], flags=re.S)]
assert len(dup) == 1 and ptext(P[425]).strip() == ''
P[425] = P[425].replace(dup[0], '')
log.append('P425: removed duplicate Table 4 picture')

# --- Bookmarks on the body headings and captions (for page numbers) ---
for i, name, e in [
        (93, '_cpCh1', 'PROJECT OVERVIEW'), (98, '_cpBg', 'Background of the Project'),
        (105, '_cpClient', 'Client Profile'), (110, '_cpEbp', 'Existing Business Process'),
        (117, '_cpEsa', 'Existing System Analysis'), (122, '_cpBpa', 'Business Process Analysis'),
        (156, '_cpRg', 'Requirements Gathering'), (164, '_cpNa', 'Needs Assessment'),
        (202, '_cpPo', 'Project Objectives'), (226, '_cpSd', 'Scope and Delimitations'),
        (231, '_cpPs', 'Project Significance'), (236, '_cpCf', 'Conceptual Framework'),
        (240, '_cpPf', 'Project Framework'), (245, '_cpDt', 'Definition of Terms'),
        (267, '_cpRl', 'Related Literature'), (269, '_cpFl', 'Foreign Literature'),
        (280, '_cpLl', 'Local Literature'), (291, '_cpRs', 'Related Studies'),
        (293, '_cpFs', 'Foreign Studies'), (306, '_cpLs', 'Local Studies'),
        (318, '_cpRt', 'Related Technologies'), (345, '_cpSdm', 'Software Development Methodologies'),
        (357, '_cpSqs', 'Software Quality Standards'), (367, '_cpSyn', 'Synthesis'),
        (372, '_cpGap', 'Project Gap'), (391, '_cpSr', 'System Requirements'),
        (428, '_cpUc', 'Use Case Diagram'), (432, '_cpSdes', 'System Design'),
        (434, '_cpErdH', 'Entity-Relationship Diagram'), (478, '_cpArchH', 'System Architecture Diagram'),
        (130, '_cpT1', 'Table 1. Gap Analysis'), (184, '_cpT2', 'Table 2. System Requirements'),
        (393, '_cpT3', 'Table 3 Functional Requirements'), (426, '_cpT4', 'Table 4 Non-Functional'),
        (109, '_cpF1', 'Figure 1 Organizational'), (115, '_cpF2', 'Figure 2 Existing Workflow'),
        (238, '_cpF3', 'Figure 3 Conceptual Framework'), (243, '_cpF4', 'Figure 4 Waterfall Model'),
        (389, '_cpF5', 'Figure 5 Waterfall Model'), (430, '_cpF6', 'Figure'),
        (436, '_cpF9', 'Figure')]:
    bm(i, name, e)

# ======================= Section 2: system alignment =======================
rep(101, 'age, gender', 'birth date, sex', expect="animal's name, age, gender, breed")
rep(229, ', and Firebase Cloud Messaging for notifications',
    ', and Firebase AI Logic for connecting to the Gemini AI model. '
    'Notifications are shown through the device’s built-in notification feature')
rep(230, ' or book appointments on their behalf', '')
ins(230, 'are not transferred into the system.',
    ' The clinic owner/admin may book an appointment only for a pet that its owner has already registered.'
    ' User accounts are deactivated by the clinic owner/admin instead of deleted, and a deactivated account'
    ' can no longer sign in. A deactivated account is permanently removed by the developer through the'
    ' Firebase console only when the clinic requests it.'
    ' Notification alerts appear on the device while the application is open or running in the background;'
    ' otherwise, they are shown in the application’s notification list the next time it is opened.')
rep(250, 'notification', 'AI reading', expect='database, user login, and notification services')
ins(320, 'Firebase Authentication, ', 'Firebase AI Logic, Firebase App Check, Flutter Local Notifications, ')
assert ptext(P[333]).startswith('Firebase Authentication is')
put(333, green_para(333,
    'Firebase App Check is a Firebase service that helps confirm that requests to the '
    'backend come from the genuine application. In CarePaw, it will check that database '
    'and AI requests come from the official CarePaw app, which helps block requests from '
    'modified or unknown clients.'))
assert ptext(P[335]).startswith('SharedPreferences is')
put(335, green_para(333,
    'Flutter Local Notifications is a Flutter package that displays notifications through '
    'the device’s own notification system. In CarePaw, it will show appointment and queue '
    'alerts on the user’s phone, and tapping an alert will open the related screen.'))
assert ptext(P[339]).startswith('The Google Gemini API')
put(339, green_para(333,
    'Firebase AI Logic is a Firebase service that allows a mobile application to use '
    'Google’s Gemini AI models through its Firebase project. In CarePaw, it will send '
    'captured medicine images to the Google Gemini API and return the extracted details, '
    'so no Gemini API key is stored in the application.'))
rep(320, 'Cloud Functions, ', '', expect='Cloud Firestore, Cloud Functions, Firebase Authentication')
strike_all(329, 'Cloud Functions is a serverless backend service')
rep(327, 'hosting, and server-side functions', 'and hosting', expect='Google Firebase is a cloud development platform')
rep(338, 'medicine names, dosage, quantity, batch numbers, and expiration dates',
    'medicine names and strength, quantity, unit, lot or batch numbers, expiration dates, and supplier names')
rep(340, 'medicine name, dosage, quantity, batch number, and expiration date',
    'medicine name and strength, quantity, unit, lot or batch number, expiration date, and supplier')
rep(342, 'Firebase Cloud Functions', 'Firebase AI Logic')
rep(342, 'validate AI responses', 'check that each AI response follows a fixed set of fields')
rep(470, ', queue updates, and inventory warnings', ' and queue updates')

# ======================= write =======================
out = []
pos = 0
for i, (a, b) in enumerate(spans):
    out.append(rest[pos:a])
    out.append(P[i])
    out.extend(after.get(i, []))
    pos = b
out.append(rest[pos:])
doc = head + '<w:body>' + ''.join(out)


def field(m):
    rpr, name = m.group(1), m.group(2)
    return (f'<w:r>{rpr}<w:fldChar w:fldCharType="begin"/></w:r>'
            f'<w:r>{rpr}<w:instrText xml:space="preserve"> PAGEREF {name} \\h </w:instrText></w:r>'
            f'<w:r>{rpr}<w:fldChar w:fldCharType="separate"/></w:r>'
            f'<w:r>{rpr}<w:t>##{name}##</w:t></w:r>'
            f'<w:r>{rpr}<w:fldChar w:fldCharType="end"/></w:r>')


doc, nf = re.subn(r'<w:r>(<w:rPr>(?:(?!<w:r>).)*?</w:rPr>)<w:t xml:space="preserve">§BM:(\w+)§</w:t></w:r>', field, doc, flags=re.S)
assert '§BM:' not in doc
names_f = set(re.findall(r'PAGEREF (\w+)', doc))
names_b = set(re.findall(r'w:name="(_cp\w+)"', doc))
assert names_f <= names_b, names_f - names_b
open(PATH, 'w', encoding='utf8').write(doc)
open(REL_PATH, 'w', encoding='utf8').write(rels)

# ---- clean copy: struck text and the old diagram removed ----
old_rid = re.search(r'Id="(rId\d+)"[^>]*Target="media/image23.png"', rels) or \
    re.search(r'Target="media/image23.png"[^>]*Id="(rId\d+)"', rels)
old_rid = old_rid.group(1)


def clean_para(p):
    if 'Delete the old diagram below' in p or f'r:embed="{old_rid}"' in p:
        return ''
    runs = re.findall(r'<w:r>(?:(?!</w:r>).)*?</w:r>|<w:r [^>]*>(?:(?!</w:r>).)*?</w:r>', p, flags=re.S)
    struck = [r for r in runs if '<w:strike/>' in r and RED in r]
    if not struck:
        return p
    for r in struck:
        p = p.replace(r, '', 1)
    left = ''.join(re.findall(r'<w:t(?: [^>]*)?>([^<]*)</w:t>', p))
    if not left.strip() and '<w:drawing' not in p and 'PAGEREF' not in p:
        return ''
    return p


h2, r2 = doc.split('<w:body>', 1)
clean = h2 + '<w:body>' + re.sub(r'<w:p[ >].*?</w:p>', lambda m: clean_para(m.group(0)), r2, flags=re.S)
open(f'{D}/../clean.document.xml', 'w', encoding='utf8').write(clean)
print('\n'.join(log))
print(len(log), 'edits;', nf, 'page fields;', len(names_b), 'bookmarks')
