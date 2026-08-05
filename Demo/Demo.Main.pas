unit Demo.Main;

interface

uses
  Winapi.Windows, Winapi.Messages, System.SysUtils, System.Variants,
  System.Classes, System.Threading, Vcl.Graphics, Vcl.Controls, Vcl.Forms,
  Vcl.Dialogs, Vcl.StdCtrls, Vcl.ExtCtrls,
  DFRest.Attributes, DFRest.Service, DFRest.Response, DFRest.Exceptions,
  DFRest.Component, DFRest.Version;

type
  TGitHubUser = class
  private
    Flogin: string;
    Fid: Integer;
    Fname: string;
    Flocation: string;
    Fbio: string;
    Fhtml_url: string;
  published
    property login: string read Flogin write Flogin;
    property id: Integer read Fid write Fid;
    property name: string read Fname write Fname;
    property location: string read Flocation write Flocation;
    property bio: string read Fbio write Fbio;
    property html_url: string read Fhtml_url write Fhtml_url;
  end;

  [DFRestBaseUrl('https://api.github.com')]
  [DFRestHeaders('User-Agent', 'DFRest-Demo')]
  [DFRestHeaders('Accept', 'application/vnd.github+json')]
  IGitHubApi = interface(IInvokable)
    ['{E7A1C2D3-4B5E-6F70-8192-A3B4C5D6E7F8}']
    [DFRestGet('/users/{user}')]
    function GetUser(const user: string): TGitHubUser;

    [DFRestGet('/users/{user}')]
    function GetUserAsync(const user: string): IFuture<TGitHubUser>;

    [DFRestGet('/users/{user}')]
    function GetUserResponse(const user: string): IDFRestResponse;

    [DFRestGet('/users/{user}')]
    function GetUserRaw(const user: string): string;
  end;

  TFormMain = class(TForm)
    PanelTop: TPanel;
    lblUser: TLabel;
    edtUser: TEdit;
    btnSync: TButton;
    btnAsync: TButton;
    btnResponse: TButton;
    btnRaw: TButton;
    memoLog: TMemo;
    DFRestClient1: TDFRestClient;
    procedure FormCreate(Sender: TObject);
    procedure btnSyncClick(Sender: TObject);
    procedure btnAsyncClick(Sender: TObject);
    procedure btnResponseClick(Sender: TObject);
    procedure btnRawClick(Sender: TObject);
  private
    function CreateApi: IGitHubApi;
    procedure Log(const S: string);
    procedure LogUser(User: TGitHubUser);
  public
  end;

var
  FormMain: TFormMain;

implementation

{$R *.dfm}

procedure TFormMain.Log(const S: string);
begin
  memoLog.Lines.Add(FormatDateTime('hh:nn:ss', Now) + '  ' + S);
end;

procedure TFormMain.LogUser(User: TGitHubUser);
begin
  if User = nil then
  begin
    Log('User = nil');
    Exit;
  end;
  Log(Format('login=%s  id=%d  name=%s', [User.login, User.id, User.name]));
  Log(Format('location=%s', [User.location]));
  Log(Format('url=%s', [User.html_url]));
  if User.bio <> '' then
    Log('bio=' + User.bio);
end;

function TFormMain.CreateApi: IGitHubApi;
begin
  Result := DFRestClient1.ForApi<IGitHubApi>;
end;

procedure TFormMain.FormCreate(Sender: TObject);
begin
  Caption := 'DFRest Demo  ' + DFRest_Version + '  —  Delphifan';
  DFRestClient1.BaseUrl := 'https://api.github.com';
  DFRestClient1.UserAgent := 'DFRest-Demo/' + DFRest_Version;
  edtUser.Text := 'octocat';
  Log('DFRest ' + DFRest_Version + ' ready. BaseUrl=' + DFRestClient1.BaseUrl);
end;

procedure TFormMain.btnSyncClick(Sender: TObject);
var
  Api: IGitHubApi;
  User: TGitHubUser;
begin
  Log('--- Sync GetUser ---');
  Api := CreateApi;
  User := nil;
  try
    User := Api.GetUser(Trim(edtUser.Text));
    LogUser(User);
  except
    on E: EDFRestStatusCode do
      Log(Format('HTTP %d: %s', [E.StatusCode, E.Message]));
    on E: Exception do
      Log('Error: ' + E.Message);
  end;
  User.Free;
end;

procedure TFormMain.btnAsyncClick(Sender: TObject);
var
  Api: IGitHubApi;
  Fut: IFuture<TGitHubUser>;
  User: TGitHubUser;
begin
  Log('--- Async GetUserAsync ---');
  Api := CreateApi;
  User := nil;
  try
    Fut := Api.GetUserAsync(Trim(edtUser.Text));
    Log('Waiting for future...');
    User := Fut.Value;
    LogUser(User);
  except
    on E: EDFRestStatusCode do
      Log(Format('HTTP %d: %s', [E.StatusCode, E.Message]));
    on E: Exception do
      Log('Error: ' + E.Message);
  end;
  User.Free;
end;

procedure TFormMain.btnResponseClick(Sender: TObject);
var
  Api: IGitHubApi;
  Resp: IDFRestResponse;
begin
  Log('--- GetUserResponse ---');
  Api := CreateApi;
  try
    Resp := Api.GetUserResponse(Trim(edtUser.Text));
    Log(Format('Status=%d  Success=%s',
      [Resp.StatusCode, BoolToStr(Resp.IsSuccessStatusCode, True)]));
    Log('Body (first 400 chars):');
    Log(Copy(Resp.Content, 1, 400));
  except
    on E: Exception do
      Log('Error: ' + E.Message);
  end;
end;

procedure TFormMain.btnRawClick(Sender: TObject);
var
  Api: IGitHubApi;
  S: string;
begin
  Log('--- GetUserRaw ---');
  Api := CreateApi;
  try
    S := Api.GetUserRaw(Trim(edtUser.Text));
    Log(Copy(S, 1, 400));
  except
    on E: Exception do
      Log('Error: ' + E.Message);
  end;
end;

end.
