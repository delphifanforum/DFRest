unit DFRest.Component;

{******************************************************************************}
{  DFRest 1.0.0                                                                }
{  TDFRestClient visual component                                              }
{                                                                              }
{  Author : Alen Ibric (Delphifan)                                             }
{  E-mail : adsdelphi@gmail.com                                                }
{  Web    : https://www.delphifan.com                                          }
{******************************************************************************}

interface

uses
  System.SysUtils,
  System.Classes,
  DFRest.Types,
  DFRest.Version,
  DFRest.Settings,
  DFRest.Service;

type
  /// <summary>Visual REST client — Tool Palette: DFRest.</summary>
  [ComponentPlatformsAttribute(pidWin32 or pidWin64)]
  TDFRestClient = class(TComponent)
  private
    FBaseUrl: string;
    FTimeout: Integer;
    FConnectionTimeout: Integer;
    FUserAgent: string;
    FAuthorization: string;
    FOnBeforeRequest: TDFRestBeforeRequestEvent;
    FOnAfterRequest: TDFRestAfterRequestEvent;
    FOnError: TDFRestErrorEvent;
    FOnGetAuthorization: TDFRestGetAuthorizationEvent;
    function GetVersion: string;
  public
    constructor Create(AOwner: TComponent); override;

    /// <summary>Build settings snapshot from published properties.</summary>
    function CreateSettings: TDFRestSettings;

    /// <summary>Create a typed API proxy using this component's settings.</summary>
    function ForApi<T: IInterface>: T;
  published
    property Version: string read GetVersion;
    property BaseUrl: string read FBaseUrl write FBaseUrl;
    property Timeout: Integer read FTimeout write FTimeout default 60000;
    property ConnectionTimeout: Integer read FConnectionTimeout write FConnectionTimeout default 60000;
    property UserAgent: string read FUserAgent write FUserAgent;
    property Authorization: string read FAuthorization write FAuthorization;

    property OnGetAuthorization: TDFRestGetAuthorizationEvent read FOnGetAuthorization write FOnGetAuthorization;
    property OnBeforeRequest: TDFRestBeforeRequestEvent read FOnBeforeRequest write FOnBeforeRequest;
    property OnAfterRequest: TDFRestAfterRequestEvent read FOnAfterRequest write FOnAfterRequest;
    property OnError: TDFRestErrorEvent read FOnError write FOnError;
  end;

implementation

{ TDFRestClient }

constructor TDFRestClient.Create(AOwner: TComponent);
begin
  inherited Create(AOwner);
  FTimeout := 60000;
  FConnectionTimeout := 60000;
  FUserAgent := 'DFRest/' + DFRest_Version;
end;

function TDFRestClient.GetVersion: string;
begin
  Result := DFRest_Version;
end;

function TDFRestClient.CreateSettings: TDFRestSettings;
var
  LSelf: TDFRestClient;
begin
  Result := TDFRestSettings.Create;
  Result.BaseUrl := FBaseUrl;
  Result.Timeout := FTimeout;
  Result.ConnectionTimeout := FConnectionTimeout;
  Result.UserAgent := FUserAgent;
  Result.Authorization := FAuthorization;
  Result.OnBeforeRequest := FOnBeforeRequest;
  Result.OnAfterRequest := FOnAfterRequest;
  Result.OnError := FOnError;
  Result.OwnerComponent := Self;
  if Assigned(FOnGetAuthorization) then
  begin
    LSelf := Self;
    Result.GetAuthorization :=
      function: string
      var
        Token: string;
      begin
        Token := LSelf.FAuthorization;
        LSelf.FOnGetAuthorization(LSelf, Token);
        Result := Token;
      end;
  end;
end;

function TDFRestClient.ForApi<T>: T;
begin
  Result := TDFRestService.&For<T>(CreateSettings, True);
end;

end.
