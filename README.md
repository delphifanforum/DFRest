# DFRest
**Type-safe REST client for Delphi** (Refit-inspired)  
**Type-safe REST client for Delphi**  
**Delphi için type-safe REST istemcisi**
Turn your REST API into a live Delphi interface.
```pascal
[DFRestGet('/users/{user}')]
function GetUser(const user: string): TGitHubUser;
```
```pascal
Api := TDFRestService.For<IGitHubApi>('https://api.github.com');
User := Api.GetUser('octocat');
```
[![Version](https://img.shields.io/badge/version-1.0.0-blue.svg)](#)
[![Delphi](https://img.shields.io/badge/Delphi-10.3%20%7C%2010.4%20%7C%2011%20%7C%2012%20%7C%2013-red.svg)](#)
[![License](https://img.shields.io/badge/author-Delphifan-green.svg)](https://www.delphifan.com)
[![Author](https://img.shields.io/badge/author-Delphifan-green.svg)](https://www.delphifan.com)
| | |
|---|---|

[4 lines collapsed]

---
## Türkçe
## 🇹🇷 Türkçe
### Nedir?
**DFRest**, REST API’yi attribute’lü Delphi arayüzüne çevirir (Refit / Retrofit tarzı).  
`TVirtualInterface` ile proxy üretir; HTTP için `THTTPClient`, JSON için `REST.Json` kullanır.
**DFRest**, REST servislerini Delphi’de attribute’lü arayüzler halinde tanımlamanızı sağlar. HTTP çağrıları, URL oluşturma ve JSON serileştirme arka planda yapılır; siz yalnızca arayüzü yazarsınız.
- Tool Palette bileşeni: `TDFRestClient`
- Sync / `IFuture` async / `IDFRestResponse`
- Delphi **10.3 · 10.4 · 11 · 12 · 13**
Kütüphane, arayüz + attribute yaklaşımından esinlenerek Delphi’ye özel olarak tasarlanmıştır (`TVirtualInterface`, `THTTPClient`, `REST.Json`, Tool Palette bileşeni).
### Özellikler
- Attribute’lü API: `[DFRestGet]`, `[DFRestPost]`, `[DFRestPut]`, `[DFRestDelete]`, `[DFRestPatch]`, `[DFRestHead]`
- Path / query / body / header parametreleri
- Görsel bileşen: **`TDFRestClient`** (Tool Palette → **DFRest**)
- Kod ile kullanım: `TDFRestService.For<T>`
- Senkron çağrılar
- Async: `IFuture<T>`
- `IDFRestResponse` ile status / body kontrolü
- Delphi **10.3 · 10.4 · 11 · 12 · 13** paketleri ve kurulum scriptleri
### Hızlı kurulum
1. Delphi’yi **kapatın**.

[8 lines collapsed]

| 13 Florence | `Install_D13.bat` |
Menü: `Install.bat`  
Kaldırma: `Install_D103.bat /uninstall`
Kaldırma: `Install_D103.bat /uninstall` (diğer sürümler aynı şekilde)
3. Delphi’yi açın → **Tool Palette → DFRest → TDFRestClient**
### Kullanım
#### 1) Visual component
#### Arayüz tanımı
Forma `TDFRestClient` bırakın, `BaseUrl` ayarlayın:
```pascal
type
  [DFRestHeaders('User-Agent', 'MyApp')]
  TGitHubUser = class
  private
    Flogin: string;
    Fid: Integer;
    Fname: string;
  published
    property login: string read Flogin write Flogin;
    property id: Integer read Fid write Fid;
    property name: string read Fname write Fname;
  end;
  [DFRestBaseUrl('https://api.github.com')]
  [DFRestHeaders('User-Agent', 'DFRest-Demo')]
  [DFRestHeaders('Accept', 'application/vnd.github+json')]
  IGitHubApi = interface(IInvokable)
    ['{...}']
    ['{E7A1C2D3-4B5E-6F70-8192-A3B4C5D6E7F8}']
    [DFRestGet('/users/{user}')]
    function GetUser(const user: string): TGitHubUser;
    [DFRestGet('/users/{user}')]
    function GetUserAsync(const user: string): IFuture<TGitHubUser>;
    [DFRestGet('/users/{user}')]
    function GetUserResponse(const user: string): IDFRestResponse;
    [DFRestPost('/user/repos')]
    function CreateRepo([DFRestBody] ARepo: TCreateRepo): TGitHubRepo;
  end;
```
#### Visual component
Forma `TDFRestClient` bırakın, Object Inspector’dan `BaseUrl`, `Timeout`, `UserAgent`, `Authorization` ayarlayın:
```pascal
var
  Api: IGitHubApi;
  User: TGitHubUser;

[1 line collapsed]

  Api := DFRestClient1.ForApi<IGitHubApi>;
  User := Api.GetUser('octocat');
  try
    // ...
    ShowMessage(User.login + ' / ' + User.name);
  finally
    User.Free;
  end;
end;
```
#### 2) Kod ile
#### Sadece kod
```pascal
Api := TDFRestService.For<IGitHubApi>('https://api.github.com');
```
#### Async / ApiResponse
#### Async
```pascal
[DFRestGet('/users/{user}')]
function GetUserAsync(const user: string): IFuture<TGitHubUser>;
Fut := Api.GetUserAsync('octocat');
User := Fut.Value; // bekler
```
[DFRestGet('/users/{user}')]
function GetUserResponse(const user: string): IDFRestResponse;
#### ApiResponse
```pascal
Resp := Api.GetUserResponse('octocat');
if Resp.IsSuccessStatusCode then
  Memo1.Text := Resp.Content;
```
DTO’lar **class** olmalı (`REST.Json`, Delphi 10.3 uyumu). Dönüş class’ını çağıran `Free` eder.
> **Not:** DTO’lar **class** olmalıdır (`REST.Json`, Delphi 10.3 uyumu). Dönüş class’ını çağıran taraf `Free` eder.
### Demo
`Demo\DFRestDemo.dproj` — GitHub `octocat` örneği (Sync / Async / ApiResponse / Raw).
`Demo\DFRestDemo.dproj` — GitHub API örneği (Sync / Async / ApiResponse / Raw JSON).
### Proje yapısı
```
DFRest/
  Source/           runtime + TDFRestClient
  Packages/         D103 … D13 (runtime + design-time)
  Demo/             VCL örnek
  Install_Dxxx.bat  otomatik kurulum
```
---
## English
## 🇬🇧 English
**DFRest** turns a REST API into a live Delphi interface using attributes, similar to [.NET Refit](https://github.com/reactiveui/refit).
### What is it?
Install with `Install_Dxxx.bat`, drop **TDFRestClient** from the **DFRest** palette, define an `IInvokable` API with `[DFRestGet]` / `[DFRestPost]` / …, then call `ForApi<T>` or `TDFRestService.For<T>`.
**DFRest** lets you describe REST APIs as Delphi interfaces with attributes. URL building, HTTP calls, and JSON (de)serialization happen under the hood — you write the interface, DFRest does the rest.
Requires Delphi 10.3+. DTOs must be classes. See `Demo\` for a GitHub sample.
The design follows the familiar *interface + attributes* style popularized by libraries such as [Refit](https://github.com/reactiveui/refit) (itself inspired by Square’s Retrofit), implemented natively for Delphi with `TVirtualInterface`, `THTTPClient`, `REST.Json`, and an optional Tool Palette component.
### Features
- HTTP attributes: `[DFRestGet]`, `[DFRestPost]`, `[DFRestPut]`, `[DFRestDelete]`, `[DFRestPatch]`, `[DFRestHead]`
- Path / query / body / header parameters
- Visual component: **`TDFRestClient`** (Tool Palette → **DFRest**)
- Code-first API: `TDFRestService.For<T>`
