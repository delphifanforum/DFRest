object FormMain: TFormMain
  Left = 0
  Top = 0
  Caption = 'DFRest Demo'
  ClientHeight = 480
  ClientWidth = 720
  Color = clBtnFace
  Font.Charset = DEFAULT_CHARSET
  Font.Color = clWindowText
  Font.Height = -12
  Font.Name = 'Segoe UI'
  Font.Style = []
  Position = poScreenCenter
  OnCreate = FormCreate
  TextHeight = 15
  object PanelTop: TPanel
    Left = 0
    Top = 0
    Width = 720
    Height = 56
    Align = alTop
    BevelOuter = bvNone
    TabOrder = 0
    object lblUser: TLabel
      Left = 12
      Top = 18
      Width = 55
      Height = 15
      Caption = 'GitHub user'
    end
    object edtUser: TEdit
      Left = 80
      Top = 14
      Width = 140
      Height = 23
      TabOrder = 0
      Text = 'octocat'
    end
    object btnSync: TButton
      Left = 236
      Top = 12
      Width = 100
      Height = 28
      Caption = 'Sync'
      TabOrder = 1
      OnClick = btnSyncClick
    end
    object btnAsync: TButton
      Left = 344
      Top = 12
      Width = 100
      Height = 28
      Caption = 'Async'
      TabOrder = 2
      OnClick = btnAsyncClick
    end
    object btnResponse: TButton
      Left = 452
      Top = 12
      Width = 100
      Height = 28
      Caption = 'ApiResponse'
      TabOrder = 3
      OnClick = btnResponseClick
    end
    object btnRaw: TButton
      Left = 560
      Top = 12
      Width = 100
      Height = 28
      Caption = 'Raw JSON'
      TabOrder = 4
      OnClick = btnRawClick
    end
  end
  object memoLog: TMemo
    Left = 0
    Top = 56
    Width = 720
    Height = 424
    Align = alClient
    ReadOnly = True
    ScrollBars = ssVertical
    TabOrder = 1
  end
  object DFRestClient1: TDFRestClient
    BaseUrl = 'https://api.github.com'
    Timeout = 60000
    ConnectionTimeout = 60000
    UserAgent = 'DFRest-Demo/1.0.0'
    Left = 40
    Top = 120
  end
end
