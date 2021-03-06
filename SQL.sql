USE [CHUNGKHOAN]
GO
/****** Object:  Table [dbo].[BANG_GIA_TRUC_TUYEN]    Script Date: 5/16/2021 9:14:11 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[BANG_GIA_TRUC_TUYEN](
	[MACP] [char](7) NOT NULL,
	[BM_GIA3] [float] NULL,
	[BM_KL3] [int] NULL,
	[BM_GIA2] [float] NULL,
	[BM_KL2] [int] NULL,
	[BM_GIA1] [float] NULL,
	[BM_KL1] [int] NULL,
	[KL_GIA] [float] NULL,
	[KL_KL] [int] NULL,
	[BB_GIA1] [float] NULL,
	[BB_KL1] [int] NULL,
	[BB_GIA2] [float] NULL,
	[BB_KL2] [int] NULL,
	[BB_GIA3] [float] NULL,
	[BB_KL3] [int] NULL,
 CONSTRAINT [PK__BANG_GIA__603F183E850626E9] PRIMARY KEY CLUSTERED 
(
	[MACP] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY]
GO
/****** Object:  Table [dbo].[LENHDAT]    Script Date: 5/16/2021 9:14:11 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[LENHDAT](
	[ID] [int] IDENTITY(1,1) NOT NULL,
	[MACP] [nchar](7) NULL,
	[NGAYDAT] [datetime] NULL,
	[LOAIGD] [nchar](1) NULL,
	[LOAILENH] [nchar](10) NULL,
	[SOLUONG] [int] NULL,
	[GIADAT] [float] NULL,
	[TRANGTHAILENH] [nvarchar](30) NULL,
PRIMARY KEY CLUSTERED 
(
	[ID] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY]
GO
/****** Object:  Table [dbo].[LENHKHOP]    Script Date: 5/16/2021 9:14:11 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[LENHKHOP](
	[IDKHOP] [int] IDENTITY(1,1) NOT NULL,
	[NGAYKHOP] [datetime] NULL,
	[SOLUONGKHOP] [int] NULL,
	[GIAKHOP] [float] NULL,
	[IDLENHDAT] [int] NULL,
PRIMARY KEY CLUSTERED 
(
	[IDKHOP] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY]
GO
ALTER TABLE [dbo].[LENHKHOP]  WITH CHECK ADD FOREIGN KEY([IDLENHDAT])
REFERENCES [dbo].[LENHDAT] ([ID])
GO
/****** Object:  StoredProcedure [dbo].[CursorLoaiGD]    Script Date: 5/16/2021 9:14:11 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROC [dbo].[CursorLoaiGD]
  @OutCrsr CURSOR VARYING OUTPUT, 
  @macp NVARCHAR( 10), @Ngay NVARCHAR( 10),  @LoaiGD CHAR 
AS
SET DATEFORMAT DMY 
IF (@LoaiGD='M') 
  SET @OutCrsr=CURSOR KEYSET FOR 
  SELECT NGAYDAT, SOLUONG, GIADAT,ID FROM LENHDAT 
  WHERE MACP=@macp 
     AND DAY(NGAYDAT)=DAY(@Ngay)AND MONTH(NGAYDAT)= MONTH(@Ngay) 	   AND YEAR(NGAYDAT)=YEAR(@Ngay)  
     AND LOAIGD=@LoaiGD AND SOLUONG >0  
    ORDER BY GIADAT DESC, NGAYDAT 
ELSE
  SET @OutCrsr=CURSOR KEYSET FOR 
  SELECT NGAYDAT, SOLUONG, GIADAT,ID FROM LENHDAT 
  WHERE MACP=@macp 
    AND DAY(NGAYDAT)=DAY(@Ngay)AND MONTH(NGAYDAT)= MONTH(@Ngay) 	AND YEAR(NGAYDAT)=YEAR(@Ngay)  
    AND LOAIGD=@LoaiGD AND SOLUONG >0  
    ORDER BY GIADAT, NGAYDAT 
OPEN @OutCrsr
GO
/****** Object:  StoredProcedure [dbo].[SP_KHOPLENH_LO]    Script Date: 5/16/2021 9:14:11 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROC [dbo].[SP_KHOPLENH_LO]
    @macp NVARCHAR(10),
    @Ngay NVARCHAR(10),
    @LoaiGD CHAR,
    @soluongMB INT,
    @giadatMB FLOAT
AS
SET DATEFORMAT DMY;
DECLARE @CrsrVar CURSOR,
        @ngaydat NVARCHAR(10),
        @soluong INT,
        @giadat FLOAT,
        @soluongkhop INT,
        @giakhop FLOAT,
        @id INT,
        @TempSLMB INT;
SET @TempSLMB = @soluongMB;
IF (@LoaiGD = 'B') EXEC CursorLoaiGD @CrsrVar OUTPUT, @macp, @Ngay, 'M';
ELSE
    EXEC CursorLoaiGD @CrsrVar OUTPUT, @macp, @Ngay, 'B';

FETCH NEXT FROM @CrsrVar
INTO @ngaydat,
     @soluong,
     @giadat,
     @id;
WHILE (@@FETCH_STATUS <> -1 AND @soluongMB > 0)
BEGIN
    --cua lenh ban
    IF (@LoaiGD = 'B')
    BEGIN
        IF (@giadatMB <= @giadat)
        BEGIN
            IF @soluongMB >= @soluong
            BEGIN
                SET @soluongkhop = @soluong;
                SET @giakhop = @giadat;
                SET @soluongMB = @soluongMB - @soluong;
                UPDATE dbo.LENHDAT
                SET SOLUONG = 0,
                    TRANGTHAILENH = N'Khớp hết'
                WHERE CURRENT OF @CrsrVar;
            END;
            ELSE
            BEGIN
                SET @soluongkhop = @soluongMB;
                SET @giakhop = @giadat;
                UPDATE dbo.LENHDAT
                SET SOLUONG = SOLUONG - @soluongMB,
                    TRANGTHAILENH = N'Khớp lệnh một phần'
                WHERE CURRENT OF @CrsrVar;
                SET @soluongMB = 0;
            END;
            SELECT @macp AS N'Mã Cổ Phiếu',
                   @Ngay AS 'Ngày',
                   @soluongkhop AS 'Số Lượng',
                   @giakhop AS 'Giá';
            -- Cập nhật table LENHKHOP
            INSERT INTO dbo.LENHKHOP
            (
                NGAYKHOP,
                SOLUONGKHOP,
                GIAKHOP,
                IDLENHDAT
            )
            VALUES
            (   GETDATE(),    -- NGAYKHOP - datetime
                @soluongkhop, -- SOLUONGKHOP - int
                @giakhop,     -- GIAKHOP - float
                @id           -- IDLENHDAT - int
                );
        END;
        ELSE
            GOTO THOAT;
        -- Còn Trường hợp lệnh gởi vào là lệnh mua
        FETCH NEXT FROM @CrsrVar
        INTO @ngaydat,
             @soluong,
             @giadat,
             @id;
    END;
    -- cua len mua
    IF (@LoaiGD = 'M')
    BEGIN
        PRINT ('cc');
       
            IF (@giadatMB >= @giadat)
            BEGIN
                IF @soluongMB >= @soluong
                BEGIN
                    SET @soluongkhop = @soluong;
                    SET @giakhop = @giadat;
                    SET @soluongMB = @soluongMB - @soluong;
                    UPDATE dbo.LENHDAT
                    SET SOLUONG = 0,
                        TRANGTHAILENH = N'Khớp hết'
                    WHERE CURRENT OF @CrsrVar;
                END;
                ELSE
                BEGIN
                    SET @soluongkhop = @soluongMB;
                    SET @giakhop = @giadat;
                    UPDATE dbo.LENHDAT
                    SET SOLUONG = SOLUONG - @soluongMB,
                        TRANGTHAILENH = N'Khớp lệnh một phần'
                    WHERE CURRENT OF @CrsrVar;
                    SET @soluongMB = 0;
                END;
                SELECT @macp AS N'Mã Cổ Phiếu',
                       @Ngay AS 'Ngày',
                       @soluongkhop AS 'Số Lượng',
                       @giakhop AS 'Giá';
                -- Cập nhật table LENHKHOP
                INSERT INTO dbo.LENHKHOP
                (
                    NGAYKHOP,
                    SOLUONGKHOP,
                    GIAKHOP,
                    IDLENHDAT
                )
                VALUES
                (   GETDATE(),    -- NGAYKHOP - datetime
                    @soluongkhop, -- SOLUONGKHOP - int
                    @giakhop,     -- GIAKHOP - float
                    @id           -- IDLENHDAT - int
                    );
            END;
            ELSE
                GOTO THOAT;
            -- Còn Trường hợp lệnh gởi vào là lệnh mua
            FETCH NEXT FROM @CrsrVar
            INTO @ngaydat,
                 @soluong,
                 @giadat,
                 @id;


    END;
END
        THOAT:
        CLOSE @CrsrVar;
        DEALLOCATE @CrsrVar;

IF @soluongMB > 0
BEGIN
    IF @soluongMB = @TempSLMB --nếu số lượng còn y nguyên thì trạng thái là chờ khớp
    BEGIN
        INSERT INTO dbo.LENHDAT
        (
            MACP,
            NGAYDAT,
            LOAIGD,
            LOAILENH,
            SOLUONG,
            GIADAT,
            TRANGTHAILENH
        )
        VALUES
        (   @macp,      -- MACP - nchar(7)
            GETDATE(),  -- NGAYDAT - datetime
            @LoaiGD,    -- LOAIGD - nchar(1)
            N'LO',      -- LOAILENH - nchar(10)
            @soluongMB, -- SOLUONG - int
            @giadatMB,  -- GIADAT - float
            N'Chờ khớp' -- TRANGTHAILENH - nvarchar(30)
            );
    END;
    ELSE --else --nếu đã khớp nhưng số lượng vẫn còn thì là khớp một phần
    BEGIN
        INSERT INTO dbo.LENHDAT
        (
            MACP,
            NGAYDAT,
            LOAIGD,
            LOAILENH,
            SOLUONG,
            GIADAT,
            TRANGTHAILENH
        )
        VALUES
        (   @macp,                -- MACP - nchar(7)
            GETDATE(),            -- NGAYDAT - datetime
            @LoaiGD,              -- LOAIGD - nchar(1)
            N'LO',                -- LOAILENH - nchar(10)
            @soluongMB,           -- SOLUONG - int
            @giadatMB,            -- GIADAT - float
            N'Khớp lệnh một phần' -- TRANGTHAILENH - nvarchar(30)
            );
    END;
END;
GO
