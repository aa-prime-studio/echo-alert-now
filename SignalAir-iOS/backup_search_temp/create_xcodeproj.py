#!/usr/bin/env python3

import os
import uuid
import subprocess

class XcodeprojGenerator:
    def __init__(self, project_name, bundle_id):
        self.project_name = project_name
        self.bundle_id = bundle_id
        self.file_refs = {}
        self.group_refs = {}
        self.build_file_refs = {}
        
    def generate_uuid(self):
        return str(uuid.uuid4()).replace('-', '').upper()[:24]
    
    def create_project(self):
        # Create Xcode project using command line tools
        try:
            # Try to use xcodegen if available
            self.create_with_xcodegen()
        except:
            # Fallback to manual creation
            self.create_manual_project()
    
    def create_with_xcodegen(self):
        project_spec = f"""
name: {self.project_name}
options:
  bundleIdPrefix: com.signalair
  deploymentTarget:
    iOS: "15.0"
targets:
  {self.project_name}:
    type: application
    platform: iOS
    sources:
      - path: {self.project_name}
        excludes:
          - "*.md"
    settings:
      base:
        PRODUCT_BUNDLE_IDENTIFIER: {self.bundle_id}
        SWIFT_VERSION: 5.9
        TARGETED_DEVICE_FAMILY: "1,2"
        IPHONEOS_DEPLOYMENT_TARGET: 15.0
        ENABLE_BITCODE: false
        SWIFT_EMIT_LOC_STRINGS: true
        GENERATE_INFOPLIST_FILE: false
        INFOPLIST_FILE: {self.project_name}/Info.plist
        ASSETCATALOG_COMPILER_APPICON_NAME: AppIcon
        ASSETCATALOG_COMPILER_GLOBAL_ACCENT_COLOR_NAME: AccentColor
      debug:
        SWIFT_ACTIVE_COMPILATION_CONDITIONS: DEBUG
      release:
        SWIFT_COMPILATION_MODE: wholemodule
"""
        
        with open('project.yml', 'w') as f:
            f.write(project_spec)
        
        # Run xcodegen
        result = subprocess.run(['xcodegen', 'generate'], 
                              capture_output=True, text=True)
        
        if result.returncode == 0:
            print("✅ Xcode project generated with xcodegen")
            os.remove('project.yml')
        else:
            raise Exception("xcodegen failed")
    
    def create_manual_project(self):
        print("📱 Creating Xcode project manually...")
        
        # Use Xcode command line tools
        try:
            # Create a temporary Swift Package Manager project and convert it
            result = subprocess.run([
                'xcrun', 'swift', 'package', 'init', 
                '--type', 'executable', '--name', self.project_name
            ], capture_output=True, text=True, cwd='.')
            
            if result.returncode != 0:
                # Create basic project structure manually
                self.create_basic_project()
        except:
            self.create_basic_project()
    
    def create_basic_project(self):
        print("📱 Creating basic Xcode project structure...")
        
        # Generate Xcode project file content
        project_content = self.generate_project_pbxproj()
        
        # Create .xcodeproj directory
        xcodeproj_dir = f"{self.project_name}.xcodeproj"
        os.makedirs(xcodeproj_dir, exist_ok=True)
        
        # Write project.pbxproj
        with open(f"{xcodeproj_dir}/project.pbxproj", 'w') as f:
            f.write(project_content)
        
        # Create xcshareddata and xcuserdata directories
        os.makedirs(f"{xcodeproj_dir}/xcshareddata/xcschemes", exist_ok=True)
        os.makedirs(f"{xcodeproj_dir}/xcuserdata", exist_ok=True)
        
        # Create scheme file
        scheme_content = self.generate_scheme()
        with open(f"{xcodeproj_dir}/xcshareddata/xcschemes/{self.project_name}.xcscheme", 'w') as f:
            f.write(scheme_content)
    
    def generate_project_pbxproj(self):
        # Collect all Swift files
        swift_files = []
        for root, dirs, files in os.walk(self.project_name):
            for file in files:
                if file.endswith('.swift'):
                    relative_path = os.path.relpath(os.path.join(root, file), self.project_name)
                    swift_files.append(relative_path)
        
        # Generate UUIDs for project elements
        project_uuid = self.generate_uuid()
        main_group_uuid = self.generate_uuid()
        target_uuid = self.generate_uuid()
        build_config_list_uuid = self.generate_uuid()
        
        # Basic project structure
        content = f"""// !$*UTF8*$!
{{
	archiveVersion = 1;
	classes = {{
	}};
	objectVersion = 56;
	objects = {{

/* Begin PBXBuildFile section */
"""
        
        # Add build files
        for swift_file in swift_files:
            build_file_uuid = self.generate_uuid()
            file_ref_uuid = self.generate_uuid()
            self.build_file_refs[swift_file] = build_file_uuid
            self.file_refs[swift_file] = file_ref_uuid
            content += f"\t\t{build_file_uuid} /* {swift_file} in Sources */ = {{isa = PBXBuildFile; fileRef = {file_ref_uuid} /* {swift_file} */; }};\n"
        
        content += """/* End PBXBuildFile section */

/* Begin PBXFileReference section */
"""
        
        # Add file references
        app_uuid = self.generate_uuid()
        info_plist_uuid = self.generate_uuid()
        
        content += f"\t\t{app_uuid} /* {self.project_name}.app */ = {{isa = PBXFileReference; explicitFileType = wrapper.application; includeInIndex = 0; path = {self.project_name}.app; sourceTree = BUILT_PRODUCTS_DIR; }};\n"
        content += f"\t\t{info_plist_uuid} /* Info.plist */ = {{isa = PBXFileReference; lastKnownFileType = text.plist.xml; path = Info.plist; sourceTree = \"<group>\"; }};\n"
        
        for swift_file in swift_files:
            file_ref_uuid = self.file_refs[swift_file]
            content += f"\t\t{file_ref_uuid} /* {swift_file} */ = {{isa = PBXFileReference; lastKnownFileType = sourcecode.swift; path = \"{swift_file}\"; sourceTree = \"<group>\"; }};\n"
        
        content += """/* End PBXFileReference section */

/* Begin PBXFrameworksBuildPhase section */
"""
        
        frameworks_uuid = self.generate_uuid()
        content += f"""\t\t{frameworks_uuid} /* Frameworks */ = {{
			isa = PBXFrameworksBuildPhase;
			buildActionMask = 2147483647;
			files = (
			);
			runOnlyForDeploymentPostprocessing = 0;
		}};
/* End PBXFrameworksBuildPhase section */

/* Begin PBXGroup section */
\t\t{main_group_uuid} = {{
			isa = PBXGroup;
			children = (
				{self.generate_uuid()} /* {self.project_name} */,
				{self.generate_uuid()} /* Products */,
			);
			sourceTree = "<group>";
		}};
/* End PBXGroup section */

/* Begin PBXNativeTarget section */
\t\t{target_uuid} /* {self.project_name} */ = {{
			isa = PBXNativeTarget;
			buildConfigurationList = {build_config_list_uuid} /* Build configuration list for PBXNativeTarget "{self.project_name}" */;
			buildPhases = (
				{self.generate_uuid()} /* Sources */,
				{frameworks_uuid} /* Frameworks */,
			);
			buildRules = (
			);
			dependencies = (
			);
			name = {self.project_name};
			productName = {self.project_name};
			productReference = {app_uuid} /* {self.project_name}.app */;
			productType = "com.apple.product-type.application";
		}};
/* End PBXNativeTarget section */

/* Begin PBXProject section */
\t\t{project_uuid} /* Project object */ = {{
			isa = PBXProject;
			attributes = {{
				BuildIndependentTargetsInParallel = 1;
				LastSwiftUpdateCheck = 1500;
				LastUpgradeCheck = 1500;
				TargetAttributes = {{
					{target_uuid} = {{
						CreatedOnToolsVersion = 15.0;
					}};
				}};
			}};
			buildConfigurationList = {self.generate_uuid()} /* Build configuration list for PBXProject "{self.project_name}" */;
			compatibilityVersion = "Xcode 14.0";
			developmentRegion = en;
			hasScannedForEncodings = 0;
			knownRegions = (
				en,
				Base,
			);
			mainGroup = {main_group_uuid};
			productRefGroup = {self.generate_uuid()} /* Products */;
			projectDirPath = "";
			projectRoot = "";
			targets = (
				{target_uuid} /* {self.project_name} */,
			);
		}};
/* End PBXProject section */

/* Begin PBXSourcesBuildPhase section */
\t\t{self.generate_uuid()} /* Sources */ = {{
			isa = PBXSourcesBuildPhase;
			buildActionMask = 2147483647;
			files = (
"""
        
        # Add source files to build phase
        for swift_file in swift_files:
            build_file_uuid = self.build_file_refs[swift_file]
            content += f"\t\t\t\t{build_file_uuid} /* {swift_file} in Sources */,\n"
        
        content += """\t\t\t);
			runOnlyForDeploymentPostprocessing = 0;
		};
/* End PBXSourcesBuildPhase section */

/* Begin XCBuildConfiguration section */
"""
        
        # Build configurations
        debug_config_uuid = self.generate_uuid()
        release_config_uuid = self.generate_uuid()
        
        content += f"""\t\t{debug_config_uuid} /* Debug */ = {{
			isa = XCBuildConfiguration;
			buildSettings = {{
				ALWAYS_SEARCH_USER_PATHS = NO;
				ASSETCATALOG_COMPILER_GENERATE_SWIFT_ASSET_SYMBOL_EXTENSIONS = YES;
				CLANG_ANALYZER_NONNULL = YES;
				CLANG_ANALYZER_NUMBER_OBJECT_CONVERSION = YES_AGGRESSIVE;
				CLANG_CXX_LANGUAGE_STANDARD = "gnu++20";
				CLANG_ENABLE_MODULES = YES;
				CLANG_ENABLE_OBJC_ARC = YES;
				CLANG_ENABLE_OBJC_WEAK = YES;
				CLANG_WARN_BLOCK_CAPTURE_AUTORELEASING = YES;
				CLANG_WARN_BOOL_CONVERSION = YES;
				CLANG_WARN_COMMA = YES;
				CLANG_WARN_CONSTANT_CONVERSION = YES;
				CLANG_WARN_DEPRECATED_OBJC_IMPLEMENTATIONS = YES;
				CLANG_WARN_DIRECT_OBJC_ISA_USAGE = YES_ERROR;
				CLANG_WARN_DOCUMENTATION_COMMENTS = YES;
				CLANG_WARN_EMPTY_BODY = YES;
				CLANG_WARN_ENUM_CONVERSION = YES;
				CLANG_WARN_INFINITE_RECURSION = YES;
				CLANG_WARN_INT_CONVERSION = YES;
				CLANG_WARN_NON_LITERAL_NULL_CONVERSION = YES;
				CLANG_WARN_OBJC_IMPLICIT_RETAIN_SELF = YES;
				CLANG_WARN_OBJC_LITERAL_CONVERSION = YES;
				CLANG_WARN_OBJC_ROOT_CLASS = YES_ERROR;
				CLANG_WARN_QUOTED_INCLUDE_IN_FRAMEWORK_HEADER = YES;
				CLANG_WARN_RANGE_LOOP_ANALYSIS = YES;
				CLANG_WARN_STRICT_PROTOTYPES = YES;
				CLANG_WARN_SUSPICIOUS_MOVE = YES;
				CLANG_WARN_UNGUARDED_AVAILABILITY = YES_AGGRESSIVE;
				CLANG_WARN_UNREACHABLE_CODE = YES;
				CLANG_WARN__DUPLICATE_METHOD_MATCH = YES;
				COPY_PHASE_STRIP = NO;
				DEBUG_INFORMATION_FORMAT = dwarf;
				ENABLE_STRICT_OBJC_MSGSEND = YES;
				ENABLE_TESTABILITY = YES;
				ENABLE_USER_SCRIPT_SANDBOXING = YES;
				GCC_C_LANGUAGE_STANDARD = gnu17;
				GCC_DYNAMIC_NO_PIC = NO;
				GCC_NO_COMMON_BLOCKS = YES;
				GCC_OPTIMIZATION_LEVEL = 0;
				GCC_PREPROCESSOR_DEFINITIONS = (
					"DEBUG=1",
					"$(inherited)",
				);
				GCC_WARN_64_TO_32_BIT_CONVERSION = YES;
				GCC_WARN_ABOUT_RETURN_TYPE = YES_ERROR;
				GCC_WARN_UNDECLARED_SELECTOR = YES;
				GCC_WARN_UNINITIALIZED_AUTOS = YES_AGGRESSIVE;
				GCC_WARN_UNUSED_FUNCTION = YES;
				GCC_WARN_UNUSED_VARIABLE = YES;
				IPHONEOS_DEPLOYMENT_TARGET = 15.0;
				LOCALIZATION_PREFERS_STRING_CATALOGS = YES;
				MTL_ENABLE_DEBUG_INFO = INCLUDE_SOURCE;
				MTL_FAST_MATH = YES;
				ONLY_ACTIVE_ARCH = YES;
				SDKROOT = iphoneos;
				SWIFT_ACTIVE_COMPILATION_CONDITIONS = "DEBUG $(inherited)";
				SWIFT_OPTIMIZATION_LEVEL = "-Onone";
			}};
			name = Debug;
		}};
\t\t{release_config_uuid} /* Release */ = {{
			isa = XCBuildConfiguration;
			buildSettings = {{
				ALWAYS_SEARCH_USER_PATHS = NO;
				ASSETCATALOG_COMPILER_GENERATE_SWIFT_ASSET_SYMBOL_EXTENSIONS = YES;
				CLANG_ANALYZER_NONNULL = YES;
				CLANG_ANALYZER_NUMBER_OBJECT_CONVERSION = YES_AGGRESSIVE;
				CLANG_CXX_LANGUAGE_STANDARD = "gnu++20";
				CLANG_ENABLE_MODULES = YES;
				CLANG_ENABLE_OBJC_ARC = YES;
				CLANG_ENABLE_OBJC_WEAK = YES;
				CLANG_WARN_BLOCK_CAPTURE_AUTORELEASING = YES;
				CLANG_WARN_BOOL_CONVERSION = YES;
				CLANG_WARN_COMMA = YES;
				CLANG_WARN_CONSTANT_CONVERSION = YES;
				CLANG_WARN_DEPRECATED_OBJC_IMPLEMENTATIONS = YES;
				CLANG_WARN_DIRECT_OBJC_ISA_USAGE = YES_ERROR;
				CLANG_WARN_DOCUMENTATION_COMMENTS = YES;
				CLANG_WARN_EMPTY_BODY = YES;
				CLANG_WARN_ENUM_CONVERSION = YES;
				CLANG_WARN_INFINITE_RECURSION = YES;
				CLANG_WARN_INT_CONVERSION = YES;
				CLANG_WARN_NON_LITERAL_NULL_CONVERSION = YES;
				CLANG_WARN_OBJC_IMPLICIT_RETAIN_SELF = YES;
				CLANG_WARN_OBJC_LITERAL_CONVERSION = YES;
				CLANG_WARN_OBJC_ROOT_CLASS = YES_ERROR;
				CLANG_WARN_QUOTED_INCLUDE_IN_FRAMEWORK_HEADER = YES;
				CLANG_WARN_RANGE_LOOP_ANALYSIS = YES;
				CLANG_WARN_STRICT_PROTOTYPES = YES;
				CLANG_WARN_SUSPICIOUS_MOVE = YES;
				CLANG_WARN_UNGUARDED_AVAILABILITY = YES_AGGRESSIVE;
				CLANG_WARN_UNREACHABLE_CODE = YES;
				CLANG_WARN__DUPLICATE_METHOD_MATCH = YES;
				COPY_PHASE_STRIP = NO;
				DEBUG_INFORMATION_FORMAT = "dwarf-with-dsym";
				ENABLE_NS_ASSERTIONS = NO;
				ENABLE_STRICT_OBJC_MSGSEND = YES;
				ENABLE_USER_SCRIPT_SANDBOXING = YES;
				GCC_C_LANGUAGE_STANDARD = gnu17;
				GCC_NO_COMMON_BLOCKS = YES;
				GCC_WARN_64_TO_32_BIT_CONVERSION = YES;
				GCC_WARN_ABOUT_RETURN_TYPE = YES_ERROR;
				GCC_WARN_UNDECLARED_SELECTOR = YES;
				GCC_WARN_UNINITIALIZED_AUTOS = YES_AGGRESSIVE;
				GCC_WARN_UNUSED_FUNCTION = YES;
				GCC_WARN_UNUSED_VARIABLE = YES;
				IPHONEOS_DEPLOYMENT_TARGET = 15.0;
				LOCALIZATION_PREFERS_STRING_CATALOGS = YES;
				MTL_ENABLE_DEBUG_INFO = NO;
				MTL_FAST_MATH = YES;
				SDKROOT = iphoneos;
				SWIFT_COMPILATION_MODE = wholemodule;
				VALIDATE_PRODUCT = YES;
			}};
			name = Release;
		}};
"""
        
        # Target build configurations
        target_debug_uuid = self.generate_uuid()
        target_release_uuid = self.generate_uuid()
        
        content += f"""\t\t{target_debug_uuid} /* Debug */ = {{
			isa = XCBuildConfiguration;
			buildSettings = {{
				ASSETCATALOG_COMPILER_APPICON_NAME = AppIcon;
				ASSETCATALOG_COMPILER_GLOBAL_ACCENT_COLOR_NAME = AccentColor;
				CODE_SIGN_STYLE = Automatic;
				CURRENT_PROJECT_VERSION = 1;
				DEVELOPMENT_ASSET_PATHS = "";
				ENABLE_PREVIEWS = YES;
				GENERATE_INFOPLIST_FILE = NO;
				INFOPLIST_FILE = {self.project_name}/Info.plist;
				INFOPLIST_KEY_UIApplicationSceneManifest_Generation = YES;
				INFOPLIST_KEY_UIApplicationSupportsIndirectInputEvents = YES;
				INFOPLIST_KEY_UILaunchScreen_Generation = YES;
				INFOPLIST_KEY_UISupportedInterfaceOrientations_iPad = "UIInterfaceOrientationPortrait UIInterfaceOrientationPortraitUpsideDown UIInterfaceOrientationLandscapeLeft UIInterfaceOrientationLandscapeRight";
				INFOPLIST_KEY_UISupportedInterfaceOrientations_iPhone = "UIInterfaceOrientationPortrait UIInterfaceOrientationLandscapeLeft UIInterfaceOrientationLandscapeRight";
				LD_RUNPATH_SEARCH_PATHS = (
					"$(inherited)",
					"@executable_path/Frameworks",
				);
				MARKETING_VERSION = 1.0;
				PRODUCT_BUNDLE_IDENTIFIER = {self.bundle_id};
				PRODUCT_NAME = "$(TARGET_NAME)";
				SWIFT_EMIT_LOC_STRINGS = YES;
				SWIFT_VERSION = 5.0;
				TARGETED_DEVICE_FAMILY = "1,2";
			}};
			name = Debug;
		}};
\t\t{target_release_uuid} /* Release */ = {{
			isa = XCBuildConfiguration;
			buildSettings = {{
				ASSETCATALOG_COMPILER_APPICON_NAME = AppIcon;
				ASSETCATALOG_COMPILER_GLOBAL_ACCENT_COLOR_NAME = AccentColor;
				CODE_SIGN_STYLE = Automatic;
				CURRENT_PROJECT_VERSION = 1;
				DEVELOPMENT_ASSET_PATHS = "";
				ENABLE_PREVIEWS = YES;
				GENERATE_INFOPLIST_FILE = NO;
				INFOPLIST_FILE = {self.project_name}/Info.plist;
				INFOPLIST_KEY_UIApplicationSceneManifest_Generation = YES;
				INFOPLIST_KEY_UIApplicationSupportsIndirectInputEvents = YES;
				INFOPLIST_KEY_UILaunchScreen_Generation = YES;
				INFOPLIST_KEY_UISupportedInterfaceOrientations_iPad = "UIInterfaceOrientationPortrait UIInterfaceOrientationPortraitUpsideDown UIInterfaceOrientationLandscapeLeft UIInterfaceOrientationLandscapeRight";
				INFOPLIST_KEY_UISupportedInterfaceOrientations_iPhone = "UIInterfaceOrientationPortrait UIInterfaceOrientationLandscapeLeft UIInterfaceOrientationLandscapeRight";
				LD_RUNPATH_SEARCH_PATHS = (
					"$(inherited)",
					"@executable_path/Frameworks",
				);
				MARKETING_VERSION = 1.0;
				PRODUCT_BUNDLE_IDENTIFIER = {self.bundle_id};
				PRODUCT_NAME = "$(TARGET_NAME)";
				SWIFT_EMIT_LOC_STRINGS = YES;
				SWIFT_VERSION = 5.0;
				TARGETED_DEVICE_FAMILY = "1,2";
			}};
			name = Release;
		}};
/* End XCBuildConfiguration section */

/* Begin XCConfigurationList section */
\t\t{build_config_list_uuid} /* Build configuration list for PBXNativeTarget "{self.project_name}" */ = {{
			isa = XCConfigurationList;
			buildConfigurations = (
				{target_debug_uuid} /* Debug */,
				{target_release_uuid} /* Release */,
			);
			defaultConfigurationIsVisible = 0;
			defaultConfigurationName = Release;
		}};
\t\t{self.generate_uuid()} /* Build configuration list for PBXProject "{self.project_name}" */ = {{
			isa = XCConfigurationList;
			buildConfigurations = (
				{debug_config_uuid} /* Debug */,
				{release_config_uuid} /* Release */,
			);
			defaultConfigurationIsVisible = 0;
			defaultConfigurationName = Release;
		}};
/* End XCConfigurationList section */
	}};
	rootObject = {project_uuid} /* Project object */;
}}
"""
        
        return content
    
    def generate_scheme(self):
        return f"""<?xml version="1.0" encoding="UTF-8"?>
<Scheme
   LastUpgradeVersion = "1500"
   version = "1.3">
   <BuildAction
      parallelizeBuildables = "YES"
      buildImplicitDependencies = "YES">
      <BuildActionEntries>
         <BuildActionEntry
            buildForTesting = "YES"
            buildForRunning = "YES"
            buildForProfiling = "YES"
            buildForArchiving = "YES"
            buildForAnalyzing = "YES">
            <BuildableReference
               BuildableIdentifier = "primary"
               BlueprintIdentifier = "{self.generate_uuid()}"
               BuildableName = "{self.project_name}.app"
               BlueprintName = "{self.project_name}"
               ReferencedContainer = "container:{self.project_name}.xcodeproj">
            </BuildableReference>
         </BuildActionEntry>
      </BuildActionEntries>
   </BuildAction>
   <TestAction
      buildConfiguration = "Debug"
      selectedDebuggerIdentifier = "Xcode.DebuggerFoundation.Debugger.LLDB"
      selectedLauncherIdentifier = "Xcode.DebuggerFoundation.Launcher.LLDB"
      shouldUseLaunchSchemeArgsEnv = "YES">
      <Testables>
      </Testables>
   </TestAction>
   <LaunchAction
      buildConfiguration = "Debug"
      selectedDebuggerIdentifier = "Xcode.DebuggerFoundation.Debugger.LLDB"
      selectedLauncherIdentifier = "Xcode.DebuggerFoundation.Launcher.LLDB"
      launchStyle = "0"
      useCustomWorkingDirectory = "NO"
      ignoresPersistentStateOnLaunch = "NO"
      debugDocumentVersioning = "YES"
      debugServiceExtension = "internal"
      allowLocationSimulation = "YES">
      <BuildableProductRunnable
         runnableDebuggingMode = "0">
         <BuildableReference
            BuildableIdentifier = "primary"
            BlueprintIdentifier = "{self.generate_uuid()}"
            BuildableName = "{self.project_name}.app"
            BlueprintName = "{self.project_name}"
            ReferencedContainer = "container:{self.project_name}.xcodeproj">
         </BuildableReference>
      </BuildableProductRunnable>
   </LaunchAction>
   <ProfileAction
      buildConfiguration = "Release"
      shouldUseLaunchSchemeArgsEnv = "YES"
      savedToolIdentifier = ""
      useCustomWorkingDirectory = "NO"
      debugDocumentVersioning = "YES">
      <BuildableProductRunnable
         runnableDebuggingMode = "0">
         <BuildableReference
            BuildableIdentifier = "primary"
            BlueprintIdentifier = "{self.generate_uuid()}"
            BuildableName = "{self.project_name}.app"
            BlueprintName = "{self.project_name}"
            ReferencedContainer = "container:{self.project_name}.xcodeproj">
         </BuildableReference>
      </BuildableProductRunnable>
   </ProfileAction>
   <AnalyzeAction
      buildConfiguration = "Debug">
   </AnalyzeAction>
   <ArchiveAction
      buildConfiguration = "Release"
      revealArchiveInOrganizer = "YES">
   </ArchiveAction>
</Scheme>
"""

if __name__ == "__main__":
    generator = XcodeprojGenerator("SignalAir", "com.signalair.app")
    generator.create_project()
    print("✅ Xcode project created successfully!") 