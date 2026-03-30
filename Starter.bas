B4A=true
Group=Default Group
ModulesStructureVersion=1
Type=Service
Version=9.9
@EndOfDesignText@
Sub Process_Globals
	Private smsInt As SmsInterceptor
	Private player As MediaPlayer
	Public player As MediaPlayer ' Изменили Private на Public
	Private smsInt As SmsInterceptor
	Private p As Phone ' Добавляем объект Phone для управления громкостью
End Sub

Sub Service_Create
	smsInt.Initialize("sms")
	player.Initialize
	If File.Exists(File.DirAssets, "alarm.mp3") Then
		player.Load(File.DirAssets, "alarm.mp3")
		player.Looping = True ' Включаем бесконечный повтор
	End If
End Sub

Sub sms_MessageReceived (From As String, Body As String) As Boolean
	Log("SMS от: " & From & " Текст: " & Body)
	
	' 1. Проверяем, есть ли отправитель в списке выбранных в Main
	Dim isAllowedSender As Boolean = False
	For Each num As String In Main.SelectedNumbers
		If From.Contains(num) Then
			isAllowedSender = True
			Exit
		End If
	Next
	
	' 2. Проверяем наличие ключевых слов (из поля ввода в Main)
	Dim isKeywordFound As Boolean = False
	' Разбиваем строку по запятой и проверяем каждое слово
	Dim words() As String = Regex.Split(",", Main.Keywords)
	For Each w As String In words
		If Body.ToUpperCase.Contains(w.Trim.ToUpperCase) Then
			isKeywordFound = True
			Exit
		End If
	Next
	
	' 3. Если номер и текст совпали — включаем тревогу
	If isAllowedSender And isKeywordFound Then
		Log("Условия совпали! Перезапуск сирены...")
		Dim i As Intent
		i.Initialize(i.ACTION_MAIN, "")
		i.SetComponent("b4a.example/.main") ' ЗАМЕНИТЕ b4a.example на ваш Package Name из Project -> Build Configurations
		i.Flags = 268435456 ' FLAG_ACTIVITY_NEW_TASK
		StartActivity(i)
		' 1. Громкость на максимум
		Dim p As Phone
		p.SetVolume(p.VOLUME_MUSIC, p.GetMaxVolume(p.VOLUME_MUSIC), True)
        
		' 2. ПРИНУДИТЕЛЬНЫЙ СБРОС И ПЕРЕЗАГРУЗКА
		If player.IsPlaying Then player.Stop
        
		' Перезагружаем файл, чтобы сбросить внутренние буферы Android
		player.Load(File.DirAssets, "alarm.mp3")
		player.Looping = True ' Включаем повтор
        
		' 3. Запуск
		player.Play
        
		Return True
	End If
	
	Return False ' Обычное SMS
End Sub

