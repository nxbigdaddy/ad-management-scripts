import pandas as pd
from collections import defaultdict

# 读取通讯录
df = pd.read_excel('示例企业气体设备（芜湖）股份有限公司通讯录.xlsx', header=9)

print('正在分析组织架构...')
print('='*80)

# 提取部门信息
org_structure = defaultdict(lambda: defaultdict(lambda: defaultdict(list)))

for idx, row in df.iterrows():
    dept_str = row['部门'] if pd.notna(row['部门']) else ''
    name = row['姓名'] if pd.notna(row['姓名']) else ''
    account = row['账号'] if pd.notna(row['账号']) else ''
    title = row['职务'] if pd.notna(row['职务']) else ''
    
    if not dept_str:
        continue
    
    # 分割多个部门（用;分隔）
    departments = dept_str.split(';')
    
    for dept in departments:
        dept = dept.strip()
        if not dept:
            continue
            
        # 解析部门层级
        parts = dept.split('/')
        
        # 清理公司名称
        if len(parts) > 0 and '示例企业' in parts[0]:
            parts[0] = '示例企业气体设备（芜湖）股份有限公司'
        
        if len(parts) >= 1:
            company = parts[0]
        if len(parts) >= 2:
            main_dept = parts[1]
        else:
            main_dept = '直属'
        if len(parts) >= 3:
            sub_dept = parts[2]
        else:
            sub_dept = ''
        if len(parts) >= 4:
            team = parts[3]
        else:
            team = ''
        
        # 存储人员信息
        person_info = {
            'name': name,
            'account': account,
            'title': title
        }
        
        if team:
            org_structure[main_dept][sub_dept][team].append(person_info)
        elif sub_dept:
            org_structure[main_dept][sub_dept][''].append(person_info)
        else:
            org_structure[main_dept][''][''].append(person_info)

# 打印组织架构
print('\n公司组织架构图')
print('='*80)
print('示例企业气体设备（芜湖）股份有限公司')
print()

# 统计各部门人数
dept_stats = {}
for main_dept, sub_depts in sorted(org_structure.items()):
    total_count = 0
    for sub_dept, teams in sub_depts.items():
        for team, persons in teams.items():
            total_count += len(persons)
    dept_stats[main_dept] = total_count

# 打印主要部门
for main_dept, sub_depts in sorted(org_structure.items()):
    total_count = dept_stats[main_dept]
    print(f'├── {main_dept} ({total_count}人)')
    
    # 打印子部门
    sub_dept_items = sorted(sub_depts.items())
    for idx, (sub_dept, teams) in enumerate(sub_dept_items):
        is_last_sub = (idx == len(sub_dept_items) - 1)
        sub_prefix = '│   └── ' if is_last_sub else '│   ├── '
        
        if sub_dept:
            sub_count = sum(len(persons) for persons in teams.values())
            print(f'{sub_prefix}{sub_dept} ({sub_count}人)')
            
            # 打印小组
            team_items = sorted(teams.items())
            for t_idx, (team, persons) in enumerate(team_items):
                if team:  # 如果有小组名称
                    is_last_team = (t_idx == len(team_items) - 1)
                    team_prefix = '│       └── ' if is_last_team else '│       ├── '
                    print(f'{team_prefix}{team} ({len(persons)}人)')

print()
print('='*80)
print('部门统计汇总')
print('='*80)

# 按人数排序
sorted_stats = sorted(dept_stats.items(), key=lambda x: x[1], reverse=True)
for dept, count in sorted_stats:
    print(f'{dept}: {count}人')

print()
print(f'总计: {sum(dept_stats.values())}人')

# 导出为文本文件
with open('org_structure.txt', 'w', encoding='utf-8') as f:
    f.write('示例企业气体设备（芜湖）股份有限公司组织架构图\n')
    f.write('='*80 + '\n\n')
    
    for main_dept, sub_depts in sorted(org_structure.items()):
        total_count = dept_stats[main_dept]
        f.write(f'{main_dept} ({total_count}人)\n')
        
        for sub_dept, teams in sorted(sub_depts.items()):
            if sub_dept:
                sub_count = sum(len(persons) for persons in teams.values())
                f.write(f'  ├── {sub_dept} ({sub_count}人)\n')
                
                for team, persons in sorted(teams.items()):
                    if team:
                        f.write(f'  │   ├── {team} ({len(persons)}人)\n')
        
        f.write('\n')
    
    f.write('='*80 + '\n')
    f.write('部门统计汇总\n')
    f.write('='*80 + '\n')
    for dept, count in sorted_stats:
        f.write(f'{dept}: {count}人\n')
    f.write(f'\n总计: {sum(dept_stats.values())}人\n')

print('\n已导出为 org_structure.txt')
