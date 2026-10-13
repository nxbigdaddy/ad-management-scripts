# AD 域账号运维脚本

> 由内部工程脱敏整理后开源。原目录：`localmg` ｜ 领域：运维工具

## 项目简介

AD 域账号导出与联系人整理脚本（PowerShell + Python + 导出 CSV）

## 技术栈

未标注

## 目录结构

```text
├── ADReports/
├── Add-UserToGroup.ps1
├── Get-ADGroupMembers.ps1
├── Get-ADInfo.ps1
├── Query-ADOUUsers.ps1
├── check_ad_displayname.py
├── contacts_export.csv
├── extract_org_structure.py
├── extract_org_structure_v2.py
├── generate_name_mapping.py
├── generate_name_mapping_v2.py
├── generate_name_mapping_v3.py
├── generate_name_mapping_v4.py
├── name_mapping.csv
├── name_mapping_v2.csv
├── name_mapping_v3.csv
├── org_structure.txt
├── org_structure_v2.txt
├── read_contacts.py
├── 示例企业气体设备（芜湖）股份有限公司通讯录.xlsx
├── 供应链管理部_Users_20260407_130702.csv
```

## 快速开始

```bash
git clone <你的仓库地址>
cd ad-management-scripts
```

- 依赖安装与启动方式请参考仓库内各子目录的 README 与配置文件。
- 所有配置模板均以 `*.example` 形式提供，请复制后填入你自己的密钥与地址。

## 脱敏说明

本仓库由内部工程导出，导出时已执行以下处理：

- **删除**：私钥与证书（`*.pem` / `*.key` / `*.pfx` / `id_rsa*` / `id_ed25519*`）、`.env` 实例文件、
  数据库与备份（`*.sql` 数据导出 / `*.db` / `*.sqlite` / `*.bak` / `*.mdf`）、cookie 与本地配置、
  依赖目录与构建产物、压缩包与安装程序、大体积媒体文件。
- **替换**：口令、API Key、Token、连接串密码、内网 IP、企业域名与企业名称，均替换为占位符。
- **保留**：可公开的源码、配置模板（`.env.example`）、文档、测试与少量必要素材。

如仍发现遗漏的敏感信息，请提交 Issue，我们会立即处理。

## 许可证

MIT
