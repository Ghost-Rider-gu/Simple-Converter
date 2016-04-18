unit Unit1;

interface

uses
    Windows, Messages, SysUtils, Variants, Classes, Graphics, Controls, Forms,
    Dialogs, ShellAPI, ShlObj, StdCtrls, ExtCtrls, Buttons, ComCtrls;

type
    TForm1 = class(TForm)
        Bevel1: TBevel;
        BitBtn1: TBitBtn;
        BitBtn2: TBitBtn;
        BitBtn3: TBitBtn;
        Edit1: TEdit;
        ListBox1: TListBox;
        StaticText2: TStaticText;
        ProgressBar1: TProgressBar;
        procedure BitBtn1Click(Sender: TObject);
        procedure BitBtn3Click(Sender: TObject);
        procedure BitBtn2Click(Sender: TObject);
        procedure FormCreate(Sender: TObject);
    private
        function  StrOemToAnsi(const aStr : String) : String; // conversion function (coding)
        procedure ShareCatalog(Path: string); // processing directory with *.txt files
        procedure TxtToPict; // translations of text in pictures
        function  LinesCount(const Filename: string): integer; // counting of number of lines in the file
    public

    end;

var
    Form1: TForm1;
    TempPath: array[0..MAX_PATH] of char; // global variable (path to the selected folder)
    Pict: TBitmap; // global variable for the picture
    Prog_Dir: string; // the variable to store the path to the program
implementation

{$R *.dfm}

{
  ===================================================================

   Convert text in jpg format

  ===================================================================
}

// quit application
procedure TForm1.BitBtn1Click(Sender: TObject);
begin
    Application.Terminate;
end;

// recoding from DOS to ANSI
function TForm1.StrOemToAnsi(const aStr: String): String;
begin
    Result := '';

    if aStr = '' then Exit;

    SetLength(Result, Length(aStr));
    OemToChar(PChar(aStr), PChar(Result));
end;

// search all the files in a directory and displays them in ListBox
procedure TForm1.ShareCatalog(Path: string);
var
    SR: TSearchRec;
begin
    ListBox1.Clear;
    if FindFirst(Path + '\*.txt', faAnyFile, SR) = 0 then
    begin
        repeat
            if (SR.Attr <> faDirectory) then
            begin
                ListBox1.Items.Add(SR.Name);
            end;
        until FindNext(SR) <> 0;
        FindClose(SR);
    end;
end;

// convert txt files to image jpg
procedure TForm1.TxtToPict;
var
    str_count:integer;
    Progress_Count:integer;

    step:integer;
    str:string;

    f:TextFile;
    i:integer;
begin

    // determine the step progress bar
    Progress_Count := 100 mod ListBox1.Count;
    ProgressBar1.Step := Progress_Count;

    // take one file from the directory and convert
    for i := 0 to ListBox1.Count - 1 do
    begin
        step := 12; // step back from the line

        // presetting Bitmap
        Pict := TBitmap.Create;
        Pict.Canvas.Font.Color := clNavy;
        Pict.Canvas.Font.Size := 12;
        str_count := LinesCount(Edit1.Text + '\' + ListBox1.Items.Strings[i]);
        Pict.Width := 850;
        Pict.Height := str_count * 28;

        AssignFile(f,Edit1.Text + '\' + ListBox1.Items.Strings[i]);
        Reset(f);
        while not eof(f) do
        begin
            Readln(f,str);
            Pict.Canvas.TextOut(12, step, StrOemToAnsi(str));
            step := step + 28;
        end;
        CloseFile(f);

        Pict.Free;
        ProgressBar1.Position := ProgressBar1.Position + Progress_Count;
    end;
    if MessageDlg('Conversion is complete!' + #13#10 + 'Open the folder with the created image files?', mtConfirmation, [mbYes, mbNo], 0) = mrYes then
    begin
        ShellExecute(handle, 'OPEN', PChar(Prog_Dir), nil, nil, SW_SHOWNORMAL);
        Application.Terminate;
    end
    else
        Application.Terminate;
end;

// browse the directory (directory selection with text documents)
procedure TForm1.BitBtn3Click(Sender: TObject);
var
    TitleName: string;
    lpItemID: PItemIDList;
    BrowseInfo: TBrowseInfo;
    DisplayName: array[0..MAX_PATH] of char;
begin
    FillChar(BrowseInfo, sizeof(TBrowseInfo), #0);
    BrowseInfo.hwndOwner := Form1.Handle;
    BrowseInfo.pszDisplayName := @DisplayName;
    TitleName := 'Select the folder with text documents';
    BrowseInfo.lpszTitle := PChar(TitleName);
    BrowseInfo.ulFlags := BIF_RETURNONLYFSDIRS;
    lpItemID := SHBrowseForFolder(BrowseInfo);
    if lpItemId <> nil then
    begin
        SHGetPathFromIDList(lpItemID, TempPath);
        Edit1.Text := TempPath;
        ShareCatalog(TempPath);
        GlobalFreePtr(lpItemID);
    end;
end;

// convert all files in pictures
procedure TForm1.BitBtn2Click(Sender: TObject);
begin
    if ListBox1.Count = 0 then
    begin
        ShowMessage('There are no files to convert !!!' + #13#10 + #13#10 + 'Select the folder with the files');
        Exit;
    end;
    TxtToPict;
end;

// count the number of lines in the file (to calculate the height of the image)
function TForm1.LinesCount(const Filename: string): integer;
var
    HFile: THandle;
    FSize, WasRead, i: Cardinal;
    Buf: array[1..4096] of byte;
begin
    Result := 0;
    HFile := CreateFile(Pchar(FileName), GENERIC_READ, FILE_SHARE_READ, nil,
    OPEN_EXISTING, FILE_ATTRIBUTE_NORMAL, 0);
    if HFile <> INVALID_HANDLE_VALUE then
    begin
        FSize := GetFileSize(HFile, nil);
        if FSize > 0 then
        begin
            Inc(Result);
            ReadFile(HFile, Buf, 4096, WasRead, nil);
            repeat
                for i := WasRead downto 1 do
                    if Buf[i] = 10 then Inc(Result);
                ReadFile(HFile, Buf, 4096, WasRead, nil);
            until WasRead = 0;
        end;
    end;
    CloseHandle(HFile);
end;

// initial Setup
procedure TForm1.FormCreate(Sender: TObject);
begin
    GetDir(0,Prog_Dir); // path to exe file
end;

end.
