import pandas as pd

# 读取通讯录
df = pd.read_excel('示例企业气体设备（芜湖）股份有限公司通讯录.xlsx', header=9)

print('通讯录数据概览：')
print(f'总记录数: {len(df)}')
print('\n前50条记录：')
print('='*100)

result = df[['姓名', '账号', '职务', '部门', '手机', '企业邮箱']].head(50)
for idx, row in result.iterrows():
    name = row['姓名'] if pd.notna(row['姓名']) else ''
    account = row['账号'] if pd.notna(row['账号']) else ''
    title = row['职务'] if pd.notna(row['职务']) else ''
    dept = row['部门'] if pd.notna(row['部门']) else ''
    phone = row['手机'] if pd.notna(row['手机']) else ''
    email = row['企业邮箱'] if pd.notna(row['企业邮箱']) else ''
    print(f'{name} | {account} | {title} | {dept}')

# 保存为CSV方便处理
df.to_csv('contacts_export.csv', index=False, encoding='utf-8-sig')
print('\n已导出为 contacts_export.csv')
