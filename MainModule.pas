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
        function StrOemToAnsi(const aStr : String) : String; // функция конвертирования (кодировки)
        procedure ShareCatalog(Path: string); // обработка каталога с текстовыми файлами
        procedure TxtToPict; // Перевод текста в картинки
        function LinesCount(const Filename: string): integer; // подсчет кол-ва строк в файле
    public

    end;

var
    Form1: TForm1;
    TempPath: array[0..MAX_PATH] of char; // Глобальная переменная (путь к выбранному каталогу)
    Pict: TBitmap; // Глобальная переменная под картинку
    Prog_Dir: string; // Переменная для хранения пути к программе
implementation

{$R *.dfm}

{
  +_+_+_+_+_+_+_+_+_+_+_+_+_+_+_+_+_+_+_+_+_+_+_+_+_+_+_+_+_+_+_+_+_

  Конвертирование документов из АРМ НВП в jpg формат

  +_+_+_+_+_+_+_+_+_+_+_+_+_+_+_+_+_+_+_+_+_+_+_+_+_+_+_+_+_+_+_+_+_
}

//Завершаем работу с приложением
procedure TForm1.BitBtn1Click(Sender: TObject);
begin
    Application.Terminate;
end;

//Перекодировка из DOS в ANSI
function TForm1.StrOemToAnsi(const aStr: String): String;
begin
    Result := '';

    if aStr = '' then Exit;

    SetLength(Result, Length(aStr));
    OemToChar(PChar(aStr), PChar(Result));
end;

//Ищем все файлы в каталоге и выводим их в ListBox
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

//Конвертируем файлы txt из АРМ НВП в картинки *.jpg
procedure TForm1.TxtToPict;
var
    f: TextFile;
    str: string;
    step: integer;
    i: integer;
    str_count: integer;
    Progress_Count: integer;
begin

    //Определяем шаг прогресс бара :)
    Progress_Count:=100 mod ListBox1.Count;
    ProgressBar1.Step:=Progress_Count;

    //Берем по одному файлу из каталога и конвертируем
    for i:=0 to ListBox1.Count-1 do
    begin

        step:=12; //шаг отступа от строки

        //предварительная настройка BitMap'а
        Pict:=TBitmap.Create;
        Pict.Canvas.Font.Color:=clNavy;
        Pict.Canvas.Font.Size:=12;
        str_count:=LinesCount(Edit1.Text+'\'+ListBox1.Items.Strings[i]);
        Pict.Width:=850;
        Pict.Height:=str_count*28;
        //-==-=-=-=-=-=-=-=-=END

        AssignFile(f,Edit1.Text+'\'+ListBox1.Items.Strings[i]);
        Reset(f);
        while not eof(f) do
        begin
            Readln(f,str);
            Pict.Canvas.TextOut(12,step,StrOemToAnsi(str));
            step:=step+28;
        end;
        CloseFile(f);

        Pict.Free; //Уничтожаем наш экземпляр TBitMap'а
        ProgressBar1.Position:=ProgressBar1.Position+Progress_Count; //Прогресс бар в работе
    end;
    if MessageDlg('Конвертирование завершено!'+#13#10+'Открыть папку с созданными графическими файлами?', mtConfirmation, [mbYes, mbNo], 0)= mrYes then
    begin
        ShellExecute(handle, 'OPEN', PChar(Prog_Dir), nil, nil, SW_SHOWNORMAL);
        Application.Terminate;
    end
    else
        Application.Terminate;
end;

//Обзор каталогов (выбор каталога с текстовыми документами)
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
    TitleName := 'Выберите каталог с текстовыми документами';
    BrowseInfo.lpszTitle := PChar(TitleName);
    BrowseInfo.ulFlags := BIF_RETURNONLYFSDIRS;
    lpItemID := SHBrowseForFolder(BrowseInfo);
    if lpItemId <> nil then
    begin
        SHGetPathFromIDList(lpItemID, TempPath);
        Edit1.Text:=TempPath;
        ShareCatalog(TempPath);
        GlobalFreePtr(lpItemID);
    end;
end;

//Конвертируем все файлы из АРМ НВП в картинки
procedure TForm1.BitBtn2Click(Sender: TObject);
begin
    if ListBox1.Count=0 then
    begin
        ShowMessage('Отсутствуют файлы для конвертирования !!!'+#13#10+#13#10+'Выберите каталог с файлами из АРМ НВП');
        Exit;
    end;
    TxtToPict;
end;

//Подсчитываем количество строк в файле (для вычисления высоты картинки)
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
                    if Buf[i] = 10 then
                        Inc(Result);
                ReadFile(HFile, Buf, 4096, WasRead, nil);
            until WasRead = 0;
        end;
    end;
    CloseHandle(HFile);
end;

//Начальные настройки программы
procedure TForm1.FormCreate(Sender: TObject);
begin
    GetDir(0,Prog_Dir); //получаем путь к exe'шнику
end;

end.
