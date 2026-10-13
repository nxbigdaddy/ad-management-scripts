import pandas as pd
import csv
import re

# 读取通讯录
df = pd.read_excel('示例企业气体设备（芜湖）股份有限公司通讯录.xlsx', header=9)

# 读取 AD 用户数据
ad_users = []
with open('ADReports/AD_Users_20260407_130236.csv', 'r', encoding='utf-8') as f:
    reader = csv.DictReader(f)
    for row in reader:
        ad_users.append({
            'ad_name': row.get('Name', ''),
            'ad_displayname': row.get('DisplayName', ''),
            'ad_samaccountname': row.get('SamAccountName', ''),
            'ad_upn': row.get('UserPrincipalName', ''),
            'ad_email': row.get('EmailAddress', ''),
            'ad_ou': row.get('OU', ''),
            'ad_enabled': row.get('Enabled', ''),
            'ad_dept': row.get('Department', ''),
            'ad_title': row.get('Title', '')
        })

# 创建 AD 用户字典（多种索引方式）
ad_by_sam = {}  # 按 SamAccountName
ad_by_name = {}  # 按 Name
ad_by_display = {}  # 按 DisplayName
ad_by_email = {}  # 按 Email

for user in ad_users:
    sam = user['ad_samaccountname'].lower().strip() if user['ad_samaccountname'] else ''
    name = user['ad_name'].lower().strip() if user['ad_name'] else ''
    display = user['ad_displayname'].lower().strip() if user['ad_displayname'] else ''
    email = user['ad_email'].lower().strip() if user['ad_email'] else ''
    
    if sam:
        ad_by_sam[sam] = user
    if name:
        ad_by_name[name] = user
    if display:
        ad_by_display[display] = user
    if email:
        ad_by_email[email] = user

# 匹配函数
def find_ad_user(contact_account, contact_name, contact_email):
    """尝试多种方式匹配 AD 用户"""
    account_lower = str(contact_account).lower().strip() if contact_account else ''
    name_lower = str(contact_name).lower().strip() if contact_name else ''
    email_lower = str(contact_email).lower().strip() if contact_email else ''
    
    # 1. 直接匹配 SamAccountName
    if account_lower in ad_by_sam:
        return ad_by_sam[account_lower], 'SamAccountName精确匹配'
    
    # 2. 尝试匹配 Name
    if account_lower in ad_by_name:
        return ad_by_name[account_lower], 'Name匹配'
    
    # 3. 尝试匹配 DisplayName
    if account_lower in ad_by_display:
        return ad_by_display[account_lower], 'DisplayName匹配'
    
    # 4. 尝试邮箱匹配
    if email_lower and email_lower in ad_by_email:
        return ad_by_email[email_lower], 'Email匹配'
    
    # 5. 模糊匹配 - 提取字母部分进行匹配
    # 例如 LuoKeQin -> luokeqin
    account_letters = re.sub(r'[^a-z]', '', account_lower)
    if account_letters:
        for sam, user in ad_by_sam.items():
            sam_letters = re.sub(r'[^a-z]', '', sam)
            if account_letters == sam_letters:
                return user, '字母模糊匹配'
    
    # 6. 尝试匹配姓名的拼音首字母缩写
    # 例如 罗克钦 -> luokeqin 或 lk
    if name_lower:
        # 尝试匹配姓名的全拼
        for sam, user in ad_by_sam.items():
            if name_lower in sam or sam in name_lower:
                return user, '姓名拼音模糊匹配'
    
    return None, None

# 匹配结果
matched = []
unmatched = []

for idx, row in df.iterrows():
    contact_name = row['姓名'] if pd.notna(row['姓名']) else ''
    contact_account = row['账号'] if pd.notna(row['账号']) else ''
    contact_title = row['职务'] if pd.notna(row['职务']) else ''
    contact_dept = row['部门'] if pd.notna(row['部门']) else ''
    contact_email = row['企业邮箱'] if pd.notna(row['企业邮箱']) else ''
    contact_phone = row['手机'] if pd.notna(row['手机']) else ''
    
    if not contact_name:
        continue
    
    # 跳过简道云
    if '简道云' in str(contact_dept):
        continue
    
    # 尝试匹配
    ad_user, match_type = find_ad_user(contact_account, contact_name, contact_email)
    
    if ad_user:
        matched.append({
            'ad_samaccountname': ad_user['ad_samaccountname'],
            'ad_displayname': ad_user['ad_displayname'],
            'ad_name': ad_user['ad_name'],
            'ad_ou': ad_user['ad_ou'],
            'ad_enabled': ad_user['ad_enabled'],
            'ad_dept': ad_user['ad_dept'],
            'ad_title': ad_user['ad_title'],
            'contact_name': contact_name,
            'contact_account': contact_account,
            'contact_dept': contact_dept,
            'contact_email': contact_email,
            'contact_phone': contact_phone,
            'match_type': match_type
        })
    else:
        unmatched.append({
            'ad_samaccountname': '',
            'ad_displayname': '',
            'ad_name': '',
            'ad_ou': '',
            'ad_enabled': '',
            'ad_dept': '',
            'ad_title': '',
            'contact_name': contact_name,
            'contact_account': contact_account,
            'contact_dept': contact_dept,
            'contact_email': contact_email,
            'contact_phone': contact_phone,
            'match_type': '未匹配'
        })

# 合并结果
all_results = matched + unmatched

# 导出为 CSV
with open('name_mapping_v2.csv', 'w', newline='', encoding='utf-8-sig') as f:
    fieldnames = ['ad_samaccountname', 'ad_displayname', 'ad_name', 'ad_ou', 'ad_enabled',
                  'contact_name', 'contact_account', 'contact_dept', 'contact_email', 'match_type']
    writer = csv.DictWriter(f, fieldnames=fieldnames)
    writer.writeheader()
    for item in all_results:
        writer.writerow({
            'ad_samaccountname': item['ad_samaccountname'],
            'ad_displayname': item['ad_displayname'],
            'ad_name': item['ad_name'],
            'ad_ou': item['ad_ou'],
            'ad_enabled': item['ad_enabled'],
            'contact_name': item['contact_name'],
            'contact_account': item['contact_account'],
            'contact_dept': item['contact_dept'],
            'contact_email': item['contact_email'],
            'match_type': item['match_type']
        })

# 打印统计
print('='*120)
print('AD 显示名更新对照表 V2（包含缩写匹配）')
print('='*120)
print(f'\n总记录数: {len(all_results)}')
print(f'匹配成功: {len(matched)}')
print(f'未匹配: {len(unmatched)}')

# 按匹配类型统计
match_types = {}
for item in matched:
    mt = item['match_type']
    match_types[mt] = match_types.get(mt, 0) + 1

print('\n匹配方式统计:')
for mt, count in sorted(match_types.items(), key=lambda x: x[1], reverse=True):
    print(f'  {mt}: {count}人')

print('\n' + '='*120)
print('匹配成功的用户（前40条）')
print('='*120)
header = ['AD用户名', 'AD当前显示名', 'AD账号', 'AD所在OU', '通讯录中文', '通讯录账号', '通讯录部门', '匹配方式']
print(f'{header[0]:<15} {header[1]:<18} {header[2]:<15} {header[3]:<25} {header[4]:<10} {header[5]:<18} {header[6]:<20} {header[7]:<12}')
print('-'*120)

for item in matched[:40]:
    ad_sam = item['ad_samaccountname'][:14] if item['ad_samaccountname'] else ''
    ad_disp = item['ad_displayname'][:16] if item['ad_displayname'] else '(空)'
    ad_name = item['ad_name'][:14] if item['ad_name'] else ''
    ad_ou = item['ad_ou']
    # 提取OU中的部门名
    if 'OU=' in ad_ou:
        ou_parts = [p.replace('OU=', '') for p in ad_ou.split(',') if 'OU=' in p]
        ad_ou_short = ou_parts[0] if ou_parts else ad_ou
    else:
        ad_ou_short = ad_ou
    ad_ou_short = ad_ou_short[:23]
    
    cn = item['contact_name'][:9]
    ca = item['contact_account'][:16] if item['contact_account'] else ''
    cd = item['contact_dept'][:18] if item['contact_dept'] else ''
    mt = item['match_type'][:10]
    
    print(f'{ad_sam:<15} {ad_disp:<18} {ad_name:<15} {ad_ou_short:<25} {cn:<10} {ca:<18} {cd:<20} {mt:<12}')

if unmatched:
    print('\n' + '='*120)
    print(f'未匹配的用户（共{len(unmatched)}人，显示前20条）')
    print('='*120)
    header2 = ['通讯录中文', '通讯录账号', '通讯录部门', '通讯录邮箱']
    print(f'{header2[0]:<12} {header2[1]:<20} {header2[2]:<40} {header2[3]:<25}')
    print('-'*120)
    for item in unmatched[:20]:
        cn = item['contact_name'][:10]
        ca = item['contact_account'][:18] if item['contact_account'] else ''
        cd = item['contact_dept'][:38] if item['contact_dept'] else ''
        ce = item['contact_email'][:23] if item['contact_email'] else ''
        print(f'{cn:<12} {ca:<20} {cd:<40} {ce:<25}')

print('\n' + '='*120)
print('已导出为 name_mapping_v2.csv，请查看并确认')
print('='*120)
