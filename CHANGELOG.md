# 更新日志

本项目在公开发布前的开发历史未逐条迁移到本仓库；以下记录自首次公开发布起的版本变更。

## [0.1.0] - 2026-10-13

首次公开发布。

### 主要能力

- 提供 PowerShell 脚本连接 Windows AD 域环境，读取用户、组织单位与计算机等对象信息（`Get-ADInfo.ps1`）。
- 支持查询指定 AD 组的成员列表（`Get-ADGroupMembers.ps1`）。
- 支持将指定用户加入指定 AD 组（`Add-UserToGroup.ps1`）。
- 支持按组织单位（OU）查询该 OU 下的用户（`Query-ADOUUsers.ps1`）。
- PowerShell 脚本通过参数接收 AD 服务器地址与域账号凭据，并声明要求 PowerShell 5.1 及以上版本。
- 提供 Python 脚本读取通讯录表格并导出 CSV，便于后续处理（`read_contacts.py`）。
- 提供 Python 脚本校验 AD 导出结果中显示名称为空的账号（`check_ad_displayname.py`）。
- 提供多版迭代的 Python 脚本，用于生成 AD 账号与通讯录之间的姓名映射关系（`generate_name_mapping*.py`）。
- 提供多版迭代的 Python 脚本，用于按部门抽取组织架构（`extract_org_structure*.py`）。
- 本仓库仅包含运维脚本，不含任何员工或域账号数据：AD 导出报表、员工姓名/手机/邮箱映射、组织架构文件已从仓库移除。
- 配置以模板形式提供，需要复制后填入自己的地址与凭据。
- 附带 MIT 许可证与贡献指南。

### 已知限制

- README 的目录结构仍列出已移除的 AD 导出报表、姓名映射与组织架构文件，与仓库实际内容不一致。
- Python 脚本引用的通讯录表格与 AD 导出 CSV 已不在仓库中，直接运行会因缺少输入文件而失败。
- 各脚本需要可访问的 AD 域环境与具备相应权限的域账号，仓库不含示例数据，无法离线演示。
- README 的技术栈标注为「未标注」，依赖版本与运行环境需自行推断。
- README 未声明其他额外限制。

### 许可证

- 见 [LICENSE](LICENSE)。
