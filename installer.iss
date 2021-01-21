#define MyAppName "Firefox Travolta"
#define MyAppVersion "1.1.2"
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
WizardStyle=modern

[Languages]
Name: "english"; MessagesFile: "compiler:Default.isl"

[Files]
Source: ".\travolta.webp"; DestDir: "{tmp}"; Flags: ignoreversion
Source: ".\unzip.exe"; DestDir: "{tmp}"; Flags: ignoreversion
Source: ".\zip.exe"; DestDir: "{tmp}"; Flags: ignoreversion
Source: ".\bzip2.dll"; DestDir: "{tmp}"; Flags: ignoreversion

[Dirs]
Name: "{tmp}\omni.ja"

[Icons]
Name: "{group}\Uninstall {#MyAppName}"; Filename: "{uninstallexe}"

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
  BrowseForFolder('Select Firefox main directory', FirefoxDir, False); 
  DirectorySelector.Text := FirefoxDir;
end;

function CheckValidFirefoxDirectory(Sender: TWizardPage): Boolean;
begin
  OmniFile := FirefoxDir + '\browser\omni.ja';
  if not FileExists(OmniFile) then
  begin
    MsgBox('The directory "' + FirefoxDir + '" does not appear to be a valid Firefox directory', mbError, MB_OK);
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
    MsgBox('Firefox does not seem to be installed, make sure you select the correct directory', mbError, MB_OK);
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
    Caption := 'Change';
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
  MsgBox('Could not patch your Firefox installation', mbError, MB_OK);
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
    HtmlFile := TmpDir + '\omni.ja\chrome\browser\content\browser\aboutNetError.xhtml';
    CssFile := TmpDir + '\omni.ja\chrome\browser\skin\classic\browser\aboutNetError.css';

    ChangePatchDescription('Copying Firefox files...');
    if not FileCopy(OmniFile, OmniZip, False) then
      PatchError();

    ChangePatchDescription('Extracting Firefox files...');
    if not Exec(TmpDir + '\unzip.exe', OmniZip + ' -d omni.ja', '', SW_HIDE, ewWaitUntilTerminated, ResultCode) then
      PatchError();

    ChangePatchDescription('Cleaning up...');
    if not DeleteFile(OmniZip) then
      PatchError();

    ChangePatchDescription('Patching...');
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

    ChangePatchDescription('Compressing patched files...');
    if not Exec(TmpDir + '\zip.exe', '-0DXqr ../omni.zip ./*', TmpDir + '\omni.ja', SW_HIDE, ewWaitUntilTerminated, ResultCode) then
      PatchError();

    ChangePatchDescription('Backing up unmodified Firefox files...');
    if FileExists(OmniFile + '.backup') and not RenameFile(OmniFile + '.backup', OmniFile + '.backup.' + GetDateTimeString('yyyy-mm-dd_hh-nn-ss', '-', '-')) then
      PatchError();
    if not RenameFile(OmniFile, OmniFile + '.backup') then
    begin
      MsgBox('Could not create a backup file, if Firefox is running, please close it and run this installation again', mbError, MB_OK);
      Abort();
    end;

    ChangePatchDescription('Copying patched files into Firefox directory...');
    if not RenameFile(OmniZip, OmniFile) then
      PatchError();

    ChangePatchDescription('Done!');
    MsgBox('Patching successful! If your Firefox was open during the installation, please restart it to see the changes', mbInformation, MB_OK); 
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

  SelectDirPage := CreateCustomPage(wpWelcome, 'Select Firefox directory', 'Please select the directory where your Firefox is installed if not detected automatically.');
  SelectDirPage.OnNextButtonClick := @CheckValidFirefoxDirectory;
  
  PatchPage := CreateCustomPage(wpInstalling, 'Patching...', 'The setup is currently patching your Firefox.');
end;

function InitializeUninstall(): Boolean;
  var FirefoxVersion: String;
  var CloseFirefoxSelectedOption: Integer;
begin
  repeat
    if FindWindowByClassName('MozillaWindowClass') <> 0 then
    begin
      CloseFirefoxSelectedOption := MsgBox('Please close Firefox before continuing and then press Retry', mbError, MB_ABORTRETRYIGNORE);
      if CloseFirefoxSelectedOption = IDABORT then
        Exit;
    end
    else
      Break;
  until CloseFirefoxSelectedOption <> IDRETRY;

  if not RegQueryStringValue(GetHKLM, 'Software\Mozilla\Mozilla Firefox', 'CurrentVersion', FirefoxVersion) then
  begin
    MsgBox('Firefox does not seem to be installed, nothing to do', mbError, MB_OK);
    Result := False;
  end
  else
  begin
    RegQueryStringValue(GetHKLM, 'Software\Mozilla\Mozilla Firefox\' + FirefoxVersion + '\Main', 'Install Directory', FirefoxDir);
    if not FileExists(FirefoxDir + '\browser\omni.ja.backup') then
    begin
      MsgBox('The backup file with original data does not exist, you might need to reinstall Firefox', mbError, MB_OK);
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
      MsgBox('Could not delete the patched content, you might need to reinstall Firefox', mbError, MB_OK);
      Abort();
    end;
    if not RenameFile(OmniFile + '.backup', OmniFile) then
    begin
      MsgBox('Could not restore the original Firefox data, you might need to reinstall Firefox', mbError, MB_OK);
      Abort();
    end;
  end;
end;
