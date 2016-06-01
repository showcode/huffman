//
// https://github.com/showcode
//

program huffman;

{$APPTYPE CONSOLE}

uses
  SysUtils;

type
  // элемент входящий одновременно в массив, двух-связный список и дерево
  PElement = ^TElement;

  TElement = record
    LeftSibling, RightSibling: PElement; // соседние элементы (в списке)
    LeftChild, RightChild: PElement; // дочерние элементы (в дереве)
    Code: Word; // код, которым будем заменять оригинальный код символа
    CodeLen: Byte; // длина кода в битах
    Frequency: Word; // частота появления символа
    Index: Byte; // оригинальный код символа
    IsVacant: Boolean; // флаг, использутся при построении дерева
  end;

  TCodeTable = array [0..255] of PElement;

var
  CodeTable: TCodeTable; // массив элементов упорядоченный по коду символа
  First, Last: PElement; // двух-связный список елементов, отсортированный по возрастанию частоты
  Root: PElement; // дерево, для вычисления кодов соответствия

  { ОБЩИЕ ПРОЦЕДУРЫ }

  // инициализация таблицы кодировки
  procedure InitCodeTable;
  var
    I: Integer;
    Elem: PElement;
  begin
    // инициализируем таблицу элементами
    for I := 0 to 255 do
    begin
      New(Elem);
      CodeTable[I] := Elem;
      with CodeTable[I]^ do
      begin
        LeftChild := nil;
        RightChild := nil;
        CodeLen := 0;
        Code := 0;
        Frequency := 0;
        IsVacant := True;
        Index := I;
      end;
    end;
    // связываем соседние элементы
    for I := 0 to 255 do
    begin
      if I = 0 then
        CodeTable[I]^.LeftSibling := nil
      else
        CodeTable[I]^.LeftSibling := CodeTable[I - 1];
      if I = 255 then
        CodeTable[I]^.RightSibling := nil
      else
        CodeTable[I]^.RightSibling := CodeTable[I + 1];
    end;
    First := CodeTable[0];
    Last := CodeTable[255];
  end;

  // уничтожение кодовой таблицы и очереди
  procedure DisposeCodeTable;
  var
    I: Byte;
  begin
    for I := 0 to 255 do
      Dispose(CodeTable[I]);
  end;

  // пузырьковая сортировка по возрастанию
  procedure SortQueueByte;
  var
    Curr, Temp: PElement;
  begin
    Curr := First;
    while Curr <> Last do
    begin
      if Curr^.Frequency > Curr^.RightSibling^.Frequency then
      begin
        Temp := Curr^.RightSibling;
        Temp^.LeftSibling := Curr^.LeftSibling;
        Curr^.LeftSibling := Temp;
        if Temp^.RightSibling <> nil then
          Temp^.RightSibling^.LeftSibling := Curr;
        Curr^.RightSibling := Temp^.RightSibling;
        Temp^.RightSibling := Curr;
        if Temp^.LeftSibling <> nil then
          Temp^.LeftSibling^.RightSibling := Temp;
        if Curr = First then
          First := Temp;
        if Temp = Last then
          Last := Curr;
        Curr := Curr^.LeftSibling;
        if Curr = First then
          Curr := Curr^.RightSibling
        else
          Curr := Curr^.LeftSibling;
      end
      else
        Curr := Curr^.RightSibling;
    end;
  end;

  // создание дерева частот вхождения
  procedure CreateTree;
  var
    Right, Left, Temp: PElement;
  begin
    // В класическом алгоритме, все узлы должны присутствовать в дереве.
    // Но мы будем исключать из дерева все узлы с частотой 0, иначе
    // у нас глубина дерева резко увеличится, что приведет к переполнениям!!!
    // Как следствие, у нас будут получаться более короткие коды
    repeat

      // поиск пары еще не добавленных в дерево элементов
      Left := First;
      while (Left <> nil) and (not Left^.IsVacant or (Left.Frequency = 0)) do
        Left := Left^.RightSibling;

      if Left = nil then
        Break;
      // следующий
      Right := Left.RightSibling;
      while (Right <> nil) and (not Right^.IsVacant or (Right.Frequency = 0)) do
        Right := Right^.RightSibling;

      if Right = nil then
        Break;

      // создаем узел связывающий пару
      New(Root);
      with Root^ do
      begin
        LeftChild := Left;
        RightChild := Right;
        CodeLen := 0;
        Code := 0;
        Frequency := LeftChild^.Frequency + RightChild^.Frequency;
        IsVacant := True;
        LeftChild^.IsVacant := False;
        RightChild^.IsVacant := False;
      end;

      // вставляем созданный узел в связанный список, не забывая, что список отсортирован
      Temp := First;
      while (Temp <> nil) and (Temp^.Frequency < Root^.Frequency) do
        Temp := Temp^.RightSibling;

      if Temp = nil then
      begin // добавление в конец
        Root^.LeftSibling := Last;
        Last^.RightSibling := Root;
        Root^.RightSibling := nil;
        Last := Root;
      end
      else
      begin // вставка перед Temp
        if Temp = First then
          First := Root;
        Root^.LeftSibling := Temp^.LeftSibling;
        Temp^.LeftSibling := Root;
        Root^.RightSibling := Temp;
        if Root^.LeftSibling <> nil then
          Root^.LeftSibling^.RightSibling := Root;
      end;
    until False;
    Root^.IsVacant := False;
  end;

  // обнуление переменных и запуск просмотра дерева с вершины
  procedure CreateCompressCode;
  var
    Code: Word;
    BitCntr: Byte;

    // просмотр дерева частот и присваивание кодировочных цепей листьям
    procedure ScanTree(P: PElement);
    begin
      // если это лист, то записываем полученный код
      if (P^.LeftChild = nil) and (P^.RightChild = nil) then
      begin
        P^.Code := Code;
        P^.CodeLen := BitCntr;
      end
      else
      begin
        Code := Code shl 1;
        BitCntr := BitCntr + 1;

        if P^.LeftChild <> nil then
        begin // если идем налево, то бит 0
          ScanTree(P^.LeftChild);
        end;

        if P^.RightChild <> nil then
        begin // если идем направо, то бит 1
          Code := Code or 1;
          ScanTree(P^.RightChild);
        end;

        // восстанавливаем предыдущее значение
        Code := Code shr 1;
        BitCntr := BitCntr - 1;
      end;
    end;

  begin
    Code := 0;
    BitCntr := 0;
    ScanTree(Root);
  end;

  // удаление дерева
  procedure DeleteTree;
  var
    Curr, Temp: PElement;
  begin
    // удаляем только узлы дерева, листья оставляем
    Curr := First;
    while Curr <> nil do
    begin
      if (Curr^.LeftChild <> nil) and (Curr^.RightChild <> nil) then
      begin
        if Curr^.LeftSibling <> nil then
          Curr^.LeftSibling^.RightSibling := Curr^.RightSibling;
        if Curr^.RightSibling <> nil then
          Curr^.RightSibling^.LeftSibling := Curr^.LeftSibling;
        if Curr = First then
          First := Curr^.RightSibling;
        if Curr = Last then
          Last := Curr^.LeftSibling;
        Temp := Curr;
        Curr := Temp^.RightSibling;
        Dispose(Temp);
      end
      else
        Curr := Curr^.RightSibling;
    end;
  end;

  { УПАКОВКА }

  // процедура непосредственного сжатия файла
  procedure PakFile(const inFileName, outFileName: string);
  var
    InFile, OutFile: file;
    I: Integer;
    BitCounter: Byte;
    Elem: PElement;
    Buff: Cardinal;
    W: Word;
    B: Byte;
  begin
    // открытие файла для архивации
    Assign(InFile, inFileName);
    Reset(InFile, 1);

    // проверяем размер файла
    if FileSize(InFile) > $FFFF then
    begin
      Writeln('The size of input file is more 64K!!!');
      Readln;
      Halt;
    end;

    // создание файла архива
    Assign(OutFile, outFileName);
    Rewrite(OutFile, 1);

    // инициализация кодовой таблицы
    InitCodeTable;
    // подсчет частот вхождений байтов в блоке
    Seek(InFile, 0);
    while not EOF(InFile) do
    begin
      BlockRead(InFile, B, 1);
      CodeTable[B]^.Frequency := CodeTable[B].Frequency + 1;
    end;
    // cортировка по возрастанию числа вхождений
    SortQueueByte;

    // сохранить массив частот вхождений в архивном файле
    for I := 0 to 255 do
    begin
      BlockWrite(OutFile, CodeTable[I]^.Frequency, SizeOf(Word));
    end;
    // сохранить оригинальный размер файла
    W := FileSize(InFile);
    BlockWrite(OutFile, W, SizeOf(Word));

    // создание дерева частот
    CreateTree;
    // cоздание кода сжатия
    CreateCompressCode;
    DeleteTree; // удаление дерева частот

    // кодируем входной файл
    Seek(InFile, 0);
    BitCounter := 0;
    Buff := 0;
    while not EOF(InFile) do
    begin
      // читаем входной символ
      BlockRead(InFile, B, 1);
      // находим соответствующий этому символу элемент в массиве
      Elem := CodeTable[B];

      Buff := Buff shl Elem^.CodeLen;// выделяем место в буфере
      Buff := Buff or Elem^.Code;// помещаем код в буфер
      BitCounter := BitCounter + Elem^.CodeLen;// увеличиваем счетчик битов
      // если битов набралось на целое слово, то скидываем его в файл
      if BitCounter >= 16 then
      begin
        BitCounter := BitCounter - 16;
        W := Word(Buff shr BitCounter);
        B := Hi(W);
        BlockWrite(OutFile, B, 1);
        B := Lo(W);
        BlockWrite(OutFile, B, 1);
      end;
    end;
    // скидываем последние биты
    if BitCounter > 0 then
    begin
      // выравниваем оставшиеся биты по правому краю и скидываем их в файл
      W := Word(Buff shl (16 - BitCounter));
      B := Hi(W);
      BlockWrite(OutFile, B, 1);
      if BitCounter > 8 then
      begin
        B := Lo(W);
        BlockWrite(OutFile, B, 1);
      end;
    end;

    DisposeCodeTable;

    // закрытие архивного файла
    Close(OutFile);
    // закрытие архивируемого файла
    Close(InFile);
  end;


  { РАСПАКОВКА }

  //распаковка одного файла
  procedure UnPakFile(const inFileName, outFileName: string);
  var
    InFile, OutFile: file;
    BitCounter: Byte;
    I: Integer;
    Elem: PElement;
    B: Byte;
    Size: Word;
  begin
    // открытие файла архива
    Assign(InFile, inFileName);
    Reset(InFile, 1);
    // создание файла для разархивации
    Assign(OutFile, outFileName);
    Rewrite(OutFile, 1);

    // инициализация кодовой таблицы
    InitCodeTable;
    // воссоздание кодовой таблицы по архивному файлу
    Seek(InFile, 0);
    for I := 0 to 255 do
    begin
      BlockRead(InFile, CodeTable[I]^.Frequency, SizeOf(Word));
    end;
    // прочитать оригинальный размер файла
    BlockRead(InFile, Size, SizeOf(Word));

    SortQueueByte;
    CreateTree;
    CreateCompressCode;

    // распаковка

    Elem := Root;

    while not EOF(InFile) do
    begin
      // читаем кодированный поток
      BlockRead(InFile, B, 1);
      BitCounter := 8;

      while Size > 0 do
      begin
        // если это лист дерева, то код найден
        if (Elem^.LeftChild = nil) and (Elem^.RightChild = nil) then
        begin
          BlockWrite(OutFile, Elem^.Index, 1); // сохраняем раскодированный байт
          Elem := Root;// следующий поиск начинаем с корня
          Size := Size - 1; // сколько байтов осталось раскодировать
        end
        else
        begin
          // закончились биты, прочитаем еще байт
          if BitCounter = 0 then
            Break;
          // если 0 идем налево по дереву
          if (B and $80) = 0 then
            Elem := Elem^.LeftChild
          else
            Elem := Elem^.RightChild;
          // удаляем обработанный бит
          B := Byte(B shl 1);
          BitCounter := BitCounter - 1;
        end;
      end;
    end;

    // очистка
    DeleteTree;
    DisposeCodeTable;

    // закрытие файлов
    Close(OutFile);
    Close(InFile);
  end;


  procedure ShowHelp;
  begin
    WriteLn('Usage:');
    WriteLn('packing: huffman p <input file> <output file>');
    WriteLn('unpacking: huffman u <input file> <output file>');
  end;

begin

  if ParamCount <> 3 then
    ShowHelp()
  else
  begin
    if ParamStr(1) = 'p' then
      PakFile(ParamStr(2), ParamStr(3))
    else if ParamStr(1) = 'u' then
      UnPakFile(ParamStr(2), ParamStr(3))
    else
      ShowHelp();
  end;

end.
