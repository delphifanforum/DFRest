unit DFRest.Service;

{******************************************************************************}
{  DFRest 1.0.0                                                                }
{  TDFRestService.For<> factory                                                }
{                                                                              }
{  Author : Alen Ibric (Delphifan)                                             }
{  E-mail : adsdelphi@gmail.com                                                }
{  Web    : https://www.delphifan.com                                          }
{******************************************************************************}

interface

uses
  System.SysUtils,
  System.TypInfo,
  DFRest.Settings,
  DFRest.Proxy,
  DFRest.Exceptions;

type
  TDFRestService = class
  public
    class function &For<T: IInterface>: T; overload; static;
    class function &For<T: IInterface>(const ABaseUrl: string): T; overload; static;
    class function &For<T: IInterface>(ASettings: TDFRestSettings;
      AOwnsSettings: Boolean = False): T; overload; static;
    class function &For<T: IInterface>(const ABaseUrl: string;
      ASettings: TDFRestSettings; AOwnsSettings: Boolean = False): T; overload; static;
  end;

implementation

{ TDFRestService }

class function TDFRestService.&For<T>: T;
begin
  Result := &For<T>('', nil, False);
end;

class function TDFRestService.&For<T>(const ABaseUrl: string): T;
begin
  Result := &For<T>(ABaseUrl, nil, False);
end;

class function TDFRestService.&For<T>(ASettings: TDFRestSettings;
  AOwnsSettings: Boolean): T;
begin
  Result := &For<T>('', ASettings, AOwnsSettings);
end;

class function TDFRestService.&For<T>(const ABaseUrl: string;
  ASettings: TDFRestSettings; AOwnsSettings: Boolean): T;
var
  Settings: TDFRestSettings;
  Owns: Boolean;
  Proxy: TDFRestProxy;
  Intf: IInterface;
begin
  if ASettings <> nil then
  begin
    if AOwnsSettings then
      Settings := ASettings
    else
      Settings := ASettings.Clone;
    Owns := True;
  end
  else
  begin
    Settings := TDFRestSettings.Create;
    Owns := True;
  end;

  if ABaseUrl <> '' then
    Settings.BaseUrl := ABaseUrl;

  Proxy := TDFRestProxy.Create(TypeInfo(T), Settings, Owns);
  if not Supports(Proxy, GetTypeData(TypeInfo(T))^.Guid, Intf) then
  begin
    Proxy.Free;
    raise EDFRestService.CreateFmt('Interface %s is not supported by proxy', [string(PTypeInfo(TypeInfo(T))^.Name)]);
  end;
  // Keep proxy alive via interface refcount (TVirtualInterface is refcounted)
  Result := T(Intf);
end;

end.
