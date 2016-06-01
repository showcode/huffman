
// https://github.com/showcode


unit huffman;

interface

uses
  Classes, SysUtils;

type
  TSequence = Cardinal; // тип для хранения последовательности бит

type
  TNode = class
  private
    FSymbol: Char;
    FFreq: TSequence;
    FSequence: TSequence;
    FLength: Byte;
    FParent: TNode;
    FLNode: TNode;
    FRNode: TNode;
    function GetIsLeaf: Boolean;
  public
    property Freq: TSequence read FFreq; // частота появления символа
    property IsLeaf: Boolean read GetIsLeaf; // является ли данный узел листом дерева
    property Sequence: TSequence read FSequence; // последовательность бит, представляющая закодированный символ
    property Length: Byte read FLength; // длина последовательности
    property Symbol: Char read FSymbol; // символ

    property Parent: TNode read FParent; // родительский узел в дереве
    property LNode: TNode read FLNode; // дочерний узел в дереве
    property RNode: TNode read FRNode; // дочерний узел в дереве
  end;

  THuffArc = class
  private
    FFreqs: array [0..255] of TNode; // таблица с частотами символов
    FNodes: array of TNode; // сортированный массив со всеми созданными узлами
    FHTree: TNode; // дерево хаффмана
    procedure BuildTree;
  public
    procedure Encode(const Input, Output: TStream);
    procedure Decode(const Input, Output: TStream);
  end;

const
  BitsOnSequence = SizeOf(TSequence) * 8; // разрядность типа

implementation

{ TNode }

function TNode.GetIsLeaf: Boolean;
begin
  Result := not Assigned(FLNode) and not Assigned(FRNode);
end;

{ THuff }

procedure THuffArc.Encode(const Input, Output: TStream);
var
  I: Integer;
  C, Buf: Byte;
  Seq, N: TSequence;
  Size: Byte;
begin
  // инициализируем таблицу частот
  for I := 0 to Length(FFreqs) - 1 do
  begin
    FFreqs[I] := TNode.Create;
    FFreqs[I].FSymbol := Chr(I);
  end;

  // подсчитываем частоты появления символов
  Input.Seek(0, soFromBeginning);
  while Input.Position < Input.Size do
  begin
    Input.ReadBuffer(C, SizeOf(C));
    Inc(FFreqs[C].FFreq);
  end;

  // строим дерево и вычисляем коды
  BuildTree;

  // сохраняем таблицу частот и размер данных в поток
  for I := 0 to Length(FFreqs) - 1 do
    Output.WriteBuffer(FFreqs[I].Freq, SizeOf(TSequence));
  N := Input.Size;
  Output.WriteBuffer(N, SizeOf(TSequence));

  // кодируем входной поток
  Input.Seek(0, soFromBeginning);
  Buf := 0; // буфер для операций с битами
  N := 0; // сколько бит в буфере
  while Input.Position < Input.Size do
  begin
    Input.ReadBuffer(C, SizeOf(C));
    // выравниваем код по правому краю
    Seq := FFreqs[C].Sequence shl (BitsOnSequence - FFreqs[C].Length);

    Size := N + FFreqs[C].Length; // сколько бит в наличии
    while Size >= 8 do
    begin
      N := 8 - N; // сколько бит в буфере нехватает до байта
      Buf := Buf or (Seq shr (BitsOnSequence - N));// копируем в буффер недостающее количество старших бит
      Seq := Seq shl N;// удаляем скопированные биты
      Output.WriteBuffer(Buf, 1);
      Buf := 0;
      N := 0;
      Dec(Size, 8);
    end;

    if Size > 0 then
    begin
      Buf := Buf or (Seq shr ((BitsOnSequence - 8) + N));// копируем оставшиеся биты
      N := Size;
    end;
  end;

  if N > 0 then
  begin
    Output.WriteBuffer(Buf, 1);
  end;

  // удаляем все узлы
  FHTree := nil;
  for I := 0 to Length(FNodes) - 1 do
    FNodes[I].Free;
  SetLength(FNodes, 0);
end;

procedure THuffArc.Decode(const Input, Output: TStream);
var
  Bits: Byte;
  C: Byte;

  function TestBit: Boolean;
  begin
    if Bits = 0 then
    begin
      Input.ReadBuffer(C, SizeOf(C));
      Bits := 8;
    end;
    Result := (C and $80) <> 0;
    C := Byte(C shl 1);
    Dec(Bits);
  end;

var
  I: Integer;
  Node: TNode;
  Size: TSequence;
begin
  // инициализируем таблицу частот
  Input.Seek(0, soFromBeginning);
  for I := 0 to Length(FFreqs) - 1 do
  begin
    FFreqs[I] := TNode.Create;
    FFreqs[I].FSymbol := Chr(I);
    with FFreqs[I] do
      Input.ReadBuffer(FFreq, SizeOf(FFreq));
  end;

  // извлекаем количество закодированных символов
  Input.ReadBuffer(Size, SizeOf(Size));

  // строим дерево и вычисляем коды
  BuildTree;

  // раскодируем входной поток
  Node := FHTree;
  Bits := 0;
  while Size > 0 do
  begin
    if TestBit then
      Node := Node.RNode // если бит установлен, то выбираем правую ветвь
    else
      Node := Node.LNode;

    if Node.IsLeaf then
    begin
      Output.WriteBuffer(Node.Symbol, 1);
      Dec(Size);
      Node := FHTree;
    end;
  end;

  // удаляем все узлы
  FHTree := nil;
  for I := 0 to Length(FNodes) - 1 do
    FNodes[I].Free;
  SetLength(FNodes, 0);
end;

procedure THuffArc.BuildTree;
var
  I, J: Integer;
  Node, Temp: TNode;
  Deep: Byte;
  Seq: TSequence;
begin
  // копируем таблицу с частотами во вспомогательный массив
  SetLength(FNodes, Length(FFreqs));
  for I := 0 to Length(FFreqs) - 1 do
    FNodes[I] := FFreqs[I];
  // и cортируем его по возрастанию частоты
  for I := 0 to Length(FNodes) - 1 do
    for J := I + 1 to Length(FNodes) - 1 do
      if FNodes[I].Freq > FNodes[J].FFreq then
      begin
        Node := FNodes[I];
        FNodes[I] := FNodes[J];
        FNodes[J] := Node;
      end;

  // строим дерево
  J := 0;
  while J < Length(FNodes) - 1 do
  begin
    // создаем узел связывающий пару
    Node := TNode.Create;
    Node.FLNode := FNodes[J];
    Node.FRNode := FNodes[J + 1];
    FNodes[J].FParent := Node;
    FNodes[J + 1].FParent := Node;
    Node.FFreq := FNodes[J].FFreq + FNodes[J + 1].Freq;
    // помещаем пока созданный узел в конце массива
    SetLength(FNodes, Length(FNodes) + 1);
    FNodes[High(FNodes)] := Node;
    // если в массиве есть большие частоты, то нужно поместить узел перед ними
    for I := J + 2 to High(FNodes) - 1 do
      if FNodes[I].Freq > Node.Freq then
      begin
        Move(FNodes[I], FNodes[I + 1], (Length(FNodes) - I - 1) * SizeOf(Pointer));
        FNodes[I] := Node;
        Break;
      end;
    Inc(J, 2);
  end;
  // поскольку частота корневого узла будет суммой всех частот,
  // то он будет всегда в конце массива
  FHTree := FNodes[High(FNodes)];

  // проходимся по дереву и расставляем коды
  I := 0;
  Node := FHTree;
  Seq := 0;
  Deep := 0;
  repeat

    if Node.IsLeaf then
    begin
      Node.FSequence := Seq;
      Node.FLength := Deep;
      if I < Deep then
        I := Deep;

      // поднимаемся к корню и ищем узел в котором мы повернули налево и в нем можно повернуть направо
      repeat
        Temp := Node;
        Node := Node.Parent;
        if not Assigned(Node) then
          Break; // это значит что мы достигли корня дерева
        Dec(Deep);
        Seq := (Seq shr 1);
      until ((Node.LNode = Temp) and Assigned(Node.RNode));

      if not Assigned(Node) then
        Break;

      // и в нем поворачиваем направо
      Inc(Deep);
      Seq := (Seq shl 1) or 1;
      Node := Node.RNode;
    end
    else
    if Assigned(Node.LNode) then
    begin
      Inc(Deep);
      Seq := (Seq shl 1) or 0;
      Node := Node.LNode; // просматриваем левую ветвь
    end
    else
    if Assigned(Node.RNode) then
    begin
      Inc(Deep);
      Seq := (Seq shl 1) or 1;
      Node := Node.LNode; // просматриваем правую ветвь
    end

  until False;

end;

end.
