#!/usr/bin/env python3
import re
import uuid

# 需要添加的檔案列表
files_to_add = [
    {
        "name": "AutonomousSystemManager.swift",
        "path": "SignalAir/Core/Services/AutonomousSystemManager.swift"
    },
    {
        "name": "AutomaticSecurityMonitor.swift", 
        "path": "SignalAir/Core/Security/AutomaticSecurityMonitor.swift"
    },
    {
        "name": "AutomaticBanSystem.swift",
        "path": "SignalAir/Core/Security/AutomaticBanSystem.swift"
    },
    {
        "name": "AutomaticSystemMaintenance.swift",
        "path": "SignalAir/Core/Services/AutomaticSystemMaintenance.swift"
    },
    {
        "name": "SystemHealthMonitor.swift",
        "path": "SignalAir/Core/Services/SystemHealthMonitor.swift"
    }
]

def generate_uuid():
    """生成24字符的UUID"""
    return str(uuid.uuid4()).replace('-', '').upper()[:24]

def add_files_to_xcode_project():
    project_file = "SignalAir-iOS/SignalAir Rescue.xcodeproj/project.pbxproj"
    
    # 讀取專案檔案
    with open(project_file, 'r') as f:
        content = f.read()
    
    # 為每個檔案生成UUID
    file_refs = {}
    build_files = {}
    
    for file_info in files_to_add:
        file_refs[file_info["name"]] = generate_uuid()
        build_files[file_info["name"]] = generate_uuid()
    
    # 在PBXFileReference區段添加檔案引用
    file_ref_section = "/* End PBXFileReference section */"
    file_ref_insertions = []
    
    for file_info in files_to_add:
        file_ref_line = f"\t\t{file_refs[file_info['name']]} /* {file_info['name']} */ = {{isa = PBXFileReference; lastKnownFileType = sourcecode.swift; path = {file_info['name']}; sourceTree = \"<group>\"; }};"
        file_ref_insertions.append(file_ref_line)
    
    # 添加檔案引用
    file_ref_insert_text = "\n".join(file_ref_insertions) + "\n"
    content = content.replace(file_ref_section, file_ref_insert_text + file_ref_section)
    
    # 在PBXBuildFile區段添加建置檔案
    build_file_section = "/* End PBXBuildFile section */"
    build_file_insertions = []
    
    for file_info in files_to_add:
        build_file_line = f"\t\t{build_files[file_info['name']]} /* {file_info['name']} in Sources */ = {{isa = PBXBuildFile; fileRef = {file_refs[file_info['name']]} /* {file_info['name']} */; }};"
        build_file_insertions.append(build_file_line)
    
    # 添加建置檔案
    build_file_insert_text = "\n".join(build_file_insertions) + "\n"
    content = content.replace(build_file_section, build_file_insert_text + build_file_section)
    
    # 在Sources區段添加檔案到建置階段
    sources_pattern = r"(files = \(\s*(?:[^;]+;\s*)*)"
    
    for file_info in files_to_add:
        sources_line = f"\t\t\t\t{build_files[file_info['name']]} /* {file_info['name']} in Sources */,"
        content = re.sub(sources_pattern, r"\1" + sources_line + "\n", content, count=1)
    
    # 找到適當的群組來添加檔案
    # 對於Core/Services檔案
    services_group_pattern = r"(Core/Services.*?children = \(\s*(?:[^;]+;\s*)*)"
    for file_info in files_to_add:
        if "Services" in file_info["path"]:
            group_line = f"\t\t\t\t{file_refs[file_info['name']]} /* {file_info['name']} */,"
            content = re.sub(services_group_pattern, r"\1" + group_line + "\n", content, count=1)
    
    # 對於Core/Security檔案
    security_group_pattern = r"(Core/Security.*?children = \(\s*(?:[^;]+;\s*)*)"
    for file_info in files_to_add:
        if "Security" in file_info["path"]:
            group_line = f"\t\t\t\t{file_refs[file_info['name']]} /* {file_info['name']} */,"
            content = re.sub(security_group_pattern, r"\1" + group_line + "\n", content, count=1)
    
    # 寫回檔案
    with open(project_file, 'w') as f:
        f.write(content)
    
    print("✅ 已將自動化系統檔案添加到Xcode專案")
    print("添加的檔案:")
    for file_info in files_to_add:
        print(f"  - {file_info['name']}")

if __name__ == "__main__":
    add_files_to_xcode_project() 