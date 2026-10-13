import csv

# 读取 AD 用户
ad_users = []
with open('ADReports/AD_Users_20260407_130236.csv', 'r', encoding='utf-8') as f:
    reader = csv.DictReader(f)
    for row in reader:
        ad_users.append(row)

# 统计显示名为空的用户
empty_display = [u for u in ad_users if not u.get('DisplayName', '').strip()]
has_display = [u for u in ad_users if u.get('DisplayName', '').strip()]

print('AD 总用户数:', len(ad_users))
print('显示名为空的用户:', len(empty_display))
print('显示名已有值的用户:', len(has_display))
print()
print('显示名为空的用户示例（前10个）:')
for u in empty_display[:10]:
    sam = u.get('SamAccountName', '')
    print(f'  {sam}')
