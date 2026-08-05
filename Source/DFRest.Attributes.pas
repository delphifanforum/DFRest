unit DFRest.Attributes;

{******************************************************************************}
{  DFRest 1.0.0                                                                }
{  REST attribute tanimlari                                                    }
{                                                                              }
{  Author : Alen Ibric (Delphifan)                                             }
{  E-mail : adsdelphi@gmail.com                                                }
{  Web    : https://www.delphifan.com                                          }
{******************************************************************************}

interface

uses
  System.SysUtils,
  DFRest.Types;

type
  DFRestHttpMethodAttribute = class(TCustomAttribute)
  private
    FMethod: TDFRestHttpMethod;
    FPath: string;
  public
    constructor Create(AMethod: TDFRestHttpMethod; const APath: string);
    property Method: TDFRestHttpMethod read FMethod;
    property Path: string read FPath;
  end;

  DFRestGetAttribute = class(DFRestHttpMethodAttribute)
  public
    constructor Create(const APath: string);
  end;

  DFRestPostAttribute = class(DFRestHttpMethodAttribute)
  public
    constructor Create(const APath: string);
  end;

  DFRestPutAttribute = class(DFRestHttpMethodAttribute)
  public
    constructor Create(const APath: string);
  end;

  DFRestDeleteAttribute = class(DFRestHttpMethodAttribute)
  public
    constructor Create(const APath: string);
  end;

  DFRestPatchAttribute = class(DFRestHttpMethodAttribute)
  public
    constructor Create(const APath: string);
  end;

  DFRestHeadAttribute = class(DFRestHttpMethodAttribute)
  public
    constructor Create(const APath: string);
  end;

  DFRestBaseUrlAttribute = class(TCustomAttribute)
  private
    FBaseUrl: string;
  public
    constructor Create(const ABaseUrl: string);
    property BaseUrl: string read FBaseUrl;
  end;

  DFRestHeadersAttribute = class(TCustomAttribute)
  private
    FName: string;
    FValue: string;
  public
    constructor Create(const AName, AValue: string);
    property Name: string read FName;
    property Value: string read FValue;
  end;

  DFRestBodyAttribute = class(TCustomAttribute);

  DFRestQueryAttribute = class(TCustomAttribute)
  private
    FName: string;
  public
    constructor Create; overload;
    constructor Create(const AName: string); overload;
    property Name: string read FName;
  end;

  DFRestHeaderAttribute = class(TCustomAttribute)
  private
    FName: string;
  public
    constructor Create(const AName: string);
    property Name: string read FName;
  end;

  DFRestAliasAsAttribute = class(TCustomAttribute)
  private
    FName: string;
  public
    constructor Create(const AName: string);
    property Name: string read FName;
  end;

implementation

{ DFRestHttpMethodAttribute }

constructor DFRestHttpMethodAttribute.Create(AMethod: TDFRestHttpMethod; const APath: string);
begin
  inherited Create;
  FMethod := AMethod;
  FPath := APath;
end;

{ DFRestGetAttribute }

constructor DFRestGetAttribute.Create(const APath: string);
begin
  inherited Create(hmGet, APath);
end;

{ DFRestPostAttribute }

constructor DFRestPostAttribute.Create(const APath: string);
begin
  inherited Create(hmPost, APath);
end;

{ DFRestPutAttribute }

constructor DFRestPutAttribute.Create(const APath: string);
begin
  inherited Create(hmPut, APath);
end;

{ DFRestDeleteAttribute }

constructor DFRestDeleteAttribute.Create(const APath: string);
begin
  inherited Create(hmDelete, APath);
end;

{ DFRestPatchAttribute }

constructor DFRestPatchAttribute.Create(const APath: string);
begin
  inherited Create(hmPatch, APath);
end;

{ DFRestHeadAttribute }

constructor DFRestHeadAttribute.Create(const APath: string);
begin
  inherited Create(hmHead, APath);
end;

{ DFRestBaseUrlAttribute }

constructor DFRestBaseUrlAttribute.Create(const ABaseUrl: string);
begin
  inherited Create;
  FBaseUrl := ABaseUrl;
end;

{ DFRestHeadersAttribute }

constructor DFRestHeadersAttribute.Create(const AName, AValue: string);
begin
  inherited Create;
  FName := AName;
  FValue := AValue;
end;

{ DFRestQueryAttribute }

constructor DFRestQueryAttribute.Create;
begin
  inherited Create;
  FName := '';
end;

constructor DFRestQueryAttribute.Create(const AName: string);
begin
  inherited Create;
  FName := AName;
end;

{ DFRestHeaderAttribute }

constructor DFRestHeaderAttribute.Create(const AName: string);
begin
  inherited Create;
  FName := AName;
end;

{ DFRestAliasAsAttribute }

constructor DFRestAliasAsAttribute.Create(const AName: string);
begin
  inherited Create;
  FName := AName;
end;

end.
