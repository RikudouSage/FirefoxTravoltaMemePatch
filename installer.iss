#define MyAppName "Firefox Travolta"
#define MyAppVersion "1.2.0"
#define MyAppPublisher "Dominik Chrástecký"

[Setup]
AppId={{07073C1D-A6FD-4D4F-BDF5-F8A53895EBC0}
AppName={#MyAppName}
AppVersion={#MyAppVersion}
AppPublisher={#MyAppPublisher}
CreateAppDir=no
DefaultGroupName={#MyAppName}
OutputDir=.
OutputBaseFilename=FirefoxTravoltaSetup
Compression=lzma
SolidCompression=yes
VersionInfoVersion={#MyAppVersion}
WizardStyle=modern

[Languages]
Name: "english"; MessagesFile: "compiler:Default.isl"
Name: "czech"; MessagesFile: "compiler:Languages\Czech.isl"

[Files]
Source: ".\travolta.webp"; DestDir: "{tmp}"; Flags: ignoreversion
Source: ".\unzip.exe"; DestDir: "{tmp}"; Flags: ignoreversion
Source: ".\zip.exe"; DestDir: "{tmp}"; Flags: ignoreversion
Source: ".\bzip2.dll"; DestDir: "{tmp}"; Flags: ignoreversion

[Dirs]
Name: "{tmp}\omni.ja"

[Icons]
Name: "{group}\Uninstall {#MyAppName}"; Filename: "{uninstallexe}"

[CustomMessages]
english.SelectFirefoxDir=Select Firefox main directory
english.InvalidDirectory=The directory "%1" does not appear to be a valid Firefox directory
english.FirefoxUndetected=Firefox could not be detected automatically, make sure you select the correct directory
english.ChangeDirButton=Change
english.GenericPatchError=Could not patch your Firefox installation
english.ProgressCopyingFiles=Copying Firefox files...
english.ProgressExtracting=Extracting Firefox files...
english.ProgressCleaningUp=Cleaning up...
english.ProgressPatching=Patching...
english.ProgressCompressing=Compressing patched files...
english.ProgressBackingUp=Backing up unmodified Firefox files...
english.ErrorBackingUp=Could not create a backup file, if Firefox is running, please close it and run this installation again
english.ProgressCopyingPatchedFiles=Copying patched files into Firefox directory...
english.ProgressDone=Done!
english.MessageDone=Patching successful! If your Firefox was open during the installation, please restart it to see the changes
english.TitleSelectFirefoxDir=Select Firefox directory
english.DescriptionSelectFirefoxDir=Please select the directory where your Firefox is installed if not detected automatically.
english.TitlePatching=Patching...
english.DescriptionPatching=The setup is currently patching your Firefox.
english.MessageCloseFirefox=Please close Firefox before continuing and then press Retry
english.UninstallFirefoxUndetected=Firefox does not seem to be installed, nothing to do
english.ErrorNoBackup=The backup file with original data does not exist, you might need to reinstall Firefox
english.ErrorFailedDelete=Could not delete the patched content, you might need to reinstall Firefox
english.ErrorFailedRestore=Could not restore the original Firefox data, you might need to reinstall Firefox

czech.SelectFirefoxDir=Zvolte složku, kde je nainstalován Firefox
czech.InvalidDirectory=Složka "%1" nevypadá jako složka, kde je nainstalován Firefox
czech.FirefoxUndetected=Nezdařilo se automaticky najít složku Firefox, ujistěte se prosím, že zvolíte správnou složku
czech.ChangeDirButton=Změnit
czech.GenericPatchError=Nezdařilo se opatchovat váš Firefox
czech.ProgressCopyingFiles=Kopírování souborů Firefoxu...
czech.ProgressExtracting=Extrahování souborů Firefoxu...
czech.ProgressCleaningUp=Uklízení...
czech.ProgressPatching=Patchování...
czech.ProgressCompressing=Komprimování opatchovaných souborů...
czech.ProgressBackingUp=Zálohování původních souborů Firefoxu...
czech.ErrorBackingUp=Nezdařilo se vytvořit soubor se zálohou, pokud Firefox běží, ukončete jej prosím a znovu spusťte tuto instalaci
czech.ProgressCopyingPatchedFiles=Kopírování opatchovaných souborů do složky s Firefoxem...
czech.ProgressDone=Hotovo!
czech.MessageDone=Patchování proběhlo úspěšně! Pokud jste měli během instalace otevřený Firefox, restartujete jej, aby se projevily změny
czech.TitleSelectFirefoxDir=Zvolte složku s Firefoxem
czech.DescriptionSelectFirefoxDir=Prosím zvolte složku, kde máte nainstalován Firefox, pokud nebyla nalezena automaticky.
czech.TitlePatching=Patchování...
czech.DescriptionPatching=Instalátor právě patchuje váš Firefox
czech.MessageCloseFirefox=Před pokračování prosím zavřete Firefox a zvolte možnost Zkusit znovu
czech.UninstallFirefoxUndetected=Vypadá to, že Firefox není nainstalovaný, není co odinstalovat
czech.ErrorNoBackup=Záloha s původními soubory neexistuje, nejspíš budete muset přeinstalovat Firefox
czech.ErrorFailedDelete=Nezdařilo se smazat opatchované soubory, možná budete muset přeinstalovat Firefox
czech.ErrorFailedRestore=Nezdařilo se obnovit zálohu dat, nejspíš budete muset přeinstalovat Firefox

[Code]
var SelectDirPage: TWizardPage;
var PatchPage: TWizardPage;
var FirefoxDir: String;
var DirectorySelector: TEdit;
var OmniFile: String;
var TmpDir: String;

function GetHKLM: Integer;
begin
  if IsWin64 then
    Result := HKLM64
  else
    Result := HKLM32;
end;

procedure ChangeDirectoryHandler(Sender: TObject);
begin
  BrowseForFolder(ExpandConstant('{cm:SelectFirefoxDir}'), FirefoxDir, False); 
  DirectorySelector.Text := FirefoxDir;
end;

function CheckValidFirefoxDirectory(Sender: TWizardPage): Boolean;
  var Message: String;
begin
  OmniFile := FirefoxDir + '\browser\omni.ja';
  if not FileExists(OmniFile) then
  begin
    Message := ExpandConstant('{cm:InvalidDirectory}');
    StringChangeEx(Message, '%1', FirefoxDir, True);
    MsgBox(Message, mbError, MB_OK);
    Result := False;
  end
  else
    Result := True;
end;

procedure SelectDirPageHandler;
  var ChangeDirButton: TButton;
  var FirefoxVersion: String;
begin 
  if not RegQueryStringValue(GetHKLM, 'Software\Mozilla\Mozilla Firefox', 'CurrentVersion', FirefoxVersion) then
  begin
    MsgBox(ExpandConstant('{cm:FirefoxUndetected}'), mbError, MB_OK);
  end
  else
  begin
    RegQueryStringValue(GetHKLM, 'Software\Mozilla\Mozilla Firefox\' + FirefoxVersion + '\Main', 'Install Directory', FirefoxDir)
  end;
  DirectorySelector := TEdit.Create(SelectDirPage);
  with DirectorySelector do
  begin
    Parent := SelectDirPage.Surface;
    Left := ScaleX(0);
    Top := ScaleY(2);
    Width := ScaleX(350);
    Height := ScaleY(21);
    TabOrder := 0;
    Text := FirefoxDir;
    Enabled := False;
  end;
  ChangeDirButton := TButton.Create(SelectDirPage);
  with ChangeDirButton do
  begin
    Parent := SelectDirPage.Surface;
    Caption := ExpandConstant('{cm:ChangeDirButton}');
    Left := ScaleX(360);
    Top := ScaleY(0);
    Width := ScaleX(91);
    Height := ScaleY(23);
    TabOrder := 1;
    OnClick := @ChangeDirectoryHandler;
  end;
end;

procedure PatchError;
begin
  MsgBox(ExpandConstant('{cm:GenericPatchError}'), mbError, MB_OK);
  Abort();
end;

procedure ChangePatchDescription(Description: String);
begin
  PatchPage.Description := Description;
end;

procedure PatchPageHandler;
  var OmniZip: String;
  var ResultCode: Integer;
  var HtmlFile: String;
  var HtmlContentAnsi: AnsiString;
  var HtmlContent: String;
  var CssFile: String;
begin
    OmniZip := TmpDir + '\omni.zip';
    HtmlFile := TmpDir + '\omni.ja\chrome\browser\content\browser\certerror\aboutNetError.xhtml';
    CssFile := TmpDir + '\omni.ja\chrome\browser\skin\classic\browser\aboutNetError.css';

    ChangePatchDescription(ExpandConstant('{cm:ProgressCopyingFiles}'));
    if not FileCopy(OmniFile, OmniZip, False) then
      PatchError();

    ChangePatchDescription(ExpandConstant('{cm:ProgressExtracting}'));
    if not Exec(TmpDir + '\unzip.exe', OmniZip + ' -d omni.ja', '', SW_HIDE, ewWaitUntilTerminated, ResultCode) then
      PatchError();

    ChangePatchDescription(ExpandConstant('{cm:ProgressCleaningUp}'));
    if not DeleteFile(OmniZip) then
      PatchError();

    ChangePatchDescription(ExpandConstant('{cm:ProgressPatching}'));
    if not LoadStringFromFile(HtmlFile, HtmlContentAnsi) then
      PatchError();
    HtmlContent := String(HtmlContentAnsi);
    if StringChangeEx(HtmlContent, '</body>', '<img id="travolta" src="chrome://browser/content/travolta.webp" /></body>', True) <= 0 then
      PatchError();
    if not SaveStringToFile(HtmlFile, AnsiString(HtmlContent), False) then
      PatchError();
    if not FileCopy(TmpDir + '\travolta.webp', TmpDir + '\omni.ja\chrome\browser\content\browser\travolta.webp', False) then
      PatchError();
    if not SaveStringToFile(CssFile, '#travolta {position:absolute;left:0;right:0;bottom:0;margin:auto;}', True) then
      PatchError();  

    ChangePatchDescription(ExpandConstant('{cm:ProgressCompressing}'));
    if not Exec(TmpDir + '\zip.exe', '-0DXqr ../omni.zip ./*', TmpDir + '\omni.ja', SW_HIDE, ewWaitUntilTerminated, ResultCode) then
      PatchError();

    ChangePatchDescription(ExpandConstant('{cm:ProgressBackingUp}'));
    if FileExists(OmniFile + '.backup') and not RenameFile(OmniFile + '.backup', OmniFile + '.backup.' + GetDateTimeString('yyyy-mm-dd_hh-nn-ss', '-', '-')) then
      PatchError();
    if not RenameFile(OmniFile, OmniFile + '.backup') then
    begin
      MsgBox(ExpandConstant('{cm:ErrorBackingUp}'), mbError, MB_OK);
      Abort();
    end;

    ChangePatchDescription(ExpandConstant('{cm:ProgressCopyingPatchedFiles}'));
    if not RenameFile(OmniZip, OmniFile) then
      PatchError();

    ChangePatchDescription(ExpandConstant('{cm:ProgressDone}'));
    MsgBox(ExpandConstant('{cm:MessageDone}'), mbInformation, MB_OK); 
end;

procedure CurPageChanged(CurrentPageID: Integer);
begin
  case CurrentPageId of
    SelectDirPage.ID: SelectDirPageHandler();
    PatchPage.ID: PatchPageHandler();
  end;
end;

procedure InitializeWizard;
begin
  TmpDir := ExpandConstant('{tmp}');

  SelectDirPage := CreateCustomPage(wpWelcome, ExpandConstant('{cm:TitleSelectFirefoxDir}'), ExpandConstant('{cm:DescriptionSelectFirefoxDir}'));
  SelectDirPage.OnNextButtonClick := @CheckValidFirefoxDirectory;
  
  PatchPage := CreateCustomPage(wpInstalling, ExpandConstant('{cm:TitlePatching}'), ExpandConstant('{cm:DescriptionPatching}'));
end;

function InitializeUninstall(): Boolean;
  var FirefoxVersion: String;
  var CloseFirefoxSelectedOption: Integer;
begin
  repeat
    if FindWindowByClassName('MozillaWindowClass') <> 0 then
    begin
      CloseFirefoxSelectedOption := MsgBox(ExpandConstant('{cm:MessageCloseFirefox}'), mbError, MB_ABORTRETRYIGNORE);
      if CloseFirefoxSelectedOption = IDABORT then
        Exit;
    end
    else
      Break;
  until CloseFirefoxSelectedOption <> IDRETRY;

  if not RegQueryStringValue(GetHKLM, 'Software\Mozilla\Mozilla Firefox', 'CurrentVersion', FirefoxVersion) then
  begin
    MsgBox(ExpandConstant('{cm:UninstallFirefoxUndetected}'), mbError, MB_OK);
    Result := False;
  end
  else
  begin
    RegQueryStringValue(GetHKLM, 'Software\Mozilla\Mozilla Firefox\' + FirefoxVersion + '\Main', 'Install Directory', FirefoxDir);
    if not FileExists(FirefoxDir + '\browser\omni.ja.backup') then
    begin
      MsgBox(ExpandConstant('{cm:ErrorNoBackup}'), mbError, MB_OK);
      Result := False;
    end
    else
      Result := True;
  end;
end;

procedure CurUninstallStepChanged(CurrentStep: TUninstallStep);
begin
  if CurrentStep = usPostUninstall then
  begin
    OmniFile := FirefoxDir + '\browser\omni.ja';
    if not DeleteFile(OmniFile) then
    begin
      MsgBox(ExpandConstant('{cm:ErrorFailedDelete}'), mbError, MB_OK);
      Abort();
    end;
    if not RenameFile(OmniFile + '.backup', OmniFile) then
    begin
      MsgBox(ExpandConstant('{cm:ErrorFailedRestore}'), mbError, MB_OK);
      Abort();
    end;
  end;
end;
