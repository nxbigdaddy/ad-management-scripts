import pandas as pd
import csv

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
            'ad_ou': row.get('OU', ''),
            'ad_enabled': row.get('Enabled', '')
        })

# 创建 AD 用户字典（按 SamAccountName 索引）
ad_dict = {user['ad_samaccountname'].lower(): user for user in ad_users}

# 匹配结果
matched = []
unmatched = []

for idx, row in df.iterrows():
    contact_name = row['姓名'] if pd.notna(row['姓名']) else ''
    contact_account = row['账号'] if pd.notna(row['账号']) else ''
    contact_title = row['职务'] if pd.notna(row['职务']) else ''
    contact_dept = row['部门'] if pd.notna(row['部门']) else ''
    contact_email = row['企业邮箱'] if pd.notna(row['企业邮箱']) else ''
    
    if not contact_name or not contact_account:
        continue
    
    # 跳过简道云
    if '简道云' in str(contact_dept):
        continue
    
    # 尝试匹配（账号转小写）
    account_lower = str(contact_account).lower().strip()
    
    if account_lower in ad_dict:
        ad_user = ad_dict[account_lower]
        matched.append({
            'contact_name': contact_name,
            'contact_account': contact_account,
            'contact_title': contact_title,
            'contact_dept': contact_dept,
            'ad_name': ad_user['ad_name'],
            'ad_displayname': ad_user['ad_displayname'],
            'ad_samaccountname': ad_user['ad_samaccountname'],
            'ad_ou': ad_user['ad_ou'],
            'ad_enabled': ad_user['ad_enabled'],
            'new_displayname': contact_name,
            'status': '匹配成功'
        })
    else:
        unmatched.append({
            'contact_name': contact_name,
            'contact_account': contact_account,
            'contact_title': contact_title,
            'contact_dept': contact_dept,
            'ad_name': '',
            'ad_displayname': '',
            'ad_samaccountname': '',
            'ad_ou': '',
            'ad_enabled': '',
            'new_displayname': contact_name,
            'status': 'AD中未找到'
        })

# 合并结果
all_results = matched + unmatched

# 导出为 CSV
with open('name_mapping.csv', 'w', newline='', encoding='utf-8-sig') as f:
    fieldnames = ['contact_name', 'contact_account', 'contact_title', 'contact_dept', 
                  'ad_name', 'ad_displayname', 'ad_samaccountname', 'ad_ou', 'ad_enabled',
                  'new_displayname', 'status']
    writer = csv.DictWriter(f, fieldnames=fieldnames)
    writer.writeheader()
    writer.writerows(all_results)

# 打印统计
print('='*100)
print('AD 显示名更新对照表')
print('='*100)
print(f'\n总记录数: {len(all_results)}')
print(f'匹配成功: {len(matched)}')
print(f'未匹配: {len(unmatched)}')

print('\n' + '='*100)
print('匹配成功的用户（前30条）')
print('='*100)
header = ['通讯录姓名', '通讯录账号', 'AD当前显示名', 'AD用户名', '新显示名', '状态']
print(f'{header[0]:<12} {header[1]:<20} {header[2]:<20} {header[3]:<15} {header[4]:<12} {header[5]:<10}')
print('-'*100)
for item in matched[:30]:
    ad_disp = item['ad_displayname'] if item['ad_displayname'] else '(空)'
    cn = item['contact_name']
    ca = item['contact_account']
    asn = item['ad_samaccountname']
    nd = item['new_displayname']
    st = item['status']
    print(f'{cn:<12} {ca:<20} {ad_disp:<20} {asn:<15} {nd:<12} {st:<10}')

if unmatched:
    print('\n' + '='*100)
    print('未匹配的用户（AD中未找到对应账号）')
    print('='*100)
    header2 = ['通讯录姓名', '通讯录账号', '部门']
    print(f'{header2[0]:<12} {header2[1]:<20} {header2[2]:<40}')
    print('-'*100)
    for item in unmatched[:20]:
        dept = item['contact_dept'][:35] + '...' if len(item['contact_dept']) > 35 else item['contact_dept']
        cn = item['contact_name']
        ca = item['contact_account']
        print(f'{cn:<12} {ca:<20} {dept:<40}')

print('\n' + '='*100)
print('已导出为 name_mapping.csv，请查看并确认')
print('='*100)
