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

# 创建 AD 用户字典
ad_by_sam = {}
ad_by_email_prefix = {}

for user in ad_users:
    sam = user['ad_samaccountname'].lower().strip() if user['ad_samaccountname'] else ''
    email = user['ad_email'].lower().strip() if user['ad_email'] else ''
    
    if sam:
        ad_by_sam[sam] = user
    if email:
        email_prefix = email.split('@')[0] if '@' in email else email
        if email_prefix:
            ad_by_email_prefix[email_prefix] = user

def get_pinyin_initials(name):
    """获取拼音首字母缩写"""
    initials = []
    for i, char in enumerate(name):
        if i == 0:
            initials.append(char.lower())
        elif char.isupper():
            initials.append(char.lower())
    return ''.join(initials)

# 匹配函数
def find_ad_user(contact_account, contact_name, contact_email):
    """尝试多种方式匹配 AD 用户 - 严格匹配"""
    account = str(contact_account).strip() if contact_account else ''
    account_lower = account.lower()
    email_lower = str(contact_email).lower().strip() if contact_email else ''
    email_prefix = email_lower.split('@')[0] if '@' in email_lower else email_lower
    
    # 1. 直接匹配 SamAccountName（不区分大小写）
    if account_lower in ad_by_sam:
        return ad_by_sam[account_lower], 'SamAccountName精确匹配'
    
    # 2. 尝试邮箱前缀匹配 SamAccountName
    if email_prefix and email_prefix in ad_by_sam:
        return ad_by_sam[email_prefix], 'Email前缀-Sam匹配'
    
    # 3. 提取通讯录账号的拼音首字母缩写
    contact_initials = get_pinyin_initials(account)
    
    # 在 AD 中查找相同缩写的用户
    candidates = []
    for sam, user in ad_by_sam.items():
        sam_initials = get_pinyin_initials(sam)
        if contact_initials == sam_initials:
            candidates.append((sam, user))
    
    # 如果只有一个候选，则匹配成功
    if len(candidates) == 1:
        return candidates[0][1], '首字母缩写匹配'
    
    # 4. 尝试全字母匹配
    contact_letters = re.sub(r'[^a-z]', '', account_lower)
    for sam, user in ad_by_sam.items():
        sam_letters = re.sub(r'[^a-z]', '', sam.lower())
        if contact_letters == sam_letters:
            return user, '全字母匹配'
    
    return None, None

# 匹配结果
matched = []
unmatched = []
used_ad_users = set()  # 记录已匹配的 AD 用户，防止重复

for idx, row in df.iterrows():
    contact_name = row['姓名'] if pd.notna(row['姓名']) else ''
    contact_account = row['账号'] if pd.notna(row['账号']) else ''
    contact_title = row['职务'] if pd.notna(row['职务']) else ''
    contact_dept = row['部门'] if pd.notna(row['部门']) else ''
    contact_email = row['企业邮箱'] if pd.notna(row['企业邮箱']) else ''
    
    if not contact_name:
        continue
    
    # 跳过简道云
    if '简道云' in str(contact_dept):
        continue
    
    # 尝试匹配
    ad_user, match_type = find_ad_user(contact_account, contact_name, contact_email)
    
    if ad_user and ad_user['ad_samaccountname'].lower() not in used_ad_users:
        used_ad_users.add(ad_user['ad_samaccountname'].lower())
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
            'match_type': match_type
        })
    else:
        unmatched.append({
            'ad_samaccountname': ad_user['ad_samaccountname'] if ad_user else '',
            'ad_displayname': ad_user['ad_displayname'] if ad_user else '',
            'ad_name': ad_user['ad_name'] if ad_user else '',
            'ad_ou': ad_user['ad_ou'] if ad_user else '',
            'ad_enabled': ad_user['ad_enabled'] if ad_user else '',
            'ad_dept': ad_user['ad_dept'] if ad_user else '',
            'ad_title': ad_user['ad_title'] if ad_user else '',
            'contact_name': contact_name,
            'contact_account': contact_account,
            'contact_dept': contact_dept,
            'contact_email': contact_email,
            'match_type': '未匹配' if not ad_user else 'AD用户已被匹配'
        })

# 合并结果
all_results = matched + unmatched

# 导出为 CSV
with open('name_mapping_v4.csv', 'w', newline='', encoding='utf-8-sig') as f:
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
print('='*130)
print('AD 显示名更新对照表 V4（去重优化版）')
print('='*130)
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

print('\n' + '='*130)
print('匹配成功的用户（前50条）')
print('='*130)
print('AD用户名        AD当前显示名       AD所在OU             通讯录中文  通讯录账号          匹配方式