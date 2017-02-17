//
//  ExcelView.m
//  xjbmmcIos
//
//  Created by 郭翰林 on 2017/2/8.
//
//

#import "ExcelView.h"
#import "ExcelLockCell.h"
#import "ExcelViewCell.h"
@interface ExcelView ()
@property(nonatomic,retain) UITableView *mTableView;
@property(nonatomic,retain) NSMutableArray *mXTableDatas;//横向单行数据列表
@property(nonatomic,retain) NSMutableArray *mYTableDatas;//如果锁定第一列则设置第一列数据集合
@property(nonatomic,retain) NSMutableArray *mFristRowDatas;//第一行数据
@property(nonatomic,retain) NSMutableArray *mScrollViewArray;//把所有滚动视图添加到该数组，滑动时监听位移，然后遍历数组改变偏移位置
@property(nonatomic) CGPoint mContentOffset;//记录每次滚动结束之后的偏移量，防止列表重刷页面时偏移量复位。
@property(nonatomic,retain) NSMutableArray *mColumeMaxWidths;//记录每列最大的宽度，自适应宽度
@end

@implementation ExcelView

/*
 // Only override drawRect: if you perform custom drawing.
 // An empty implementation adversely affects performance during animation.
 - (void)drawRect:(CGRect)rect {
 // Drawing code
 }
 */
-(instancetype)initWithCoder:(NSCoder *)aDecoder{
    if (self = [super initWithCoder:aDecoder]) {
//        NSLog(@"initWithCoder");
    }
    return self;
}

-(instancetype)initWithFrame:(CGRect)frame{
    if(self=[super initWithFrame:frame]){
//        NSLog(@"initWithFrame");
        [self initView];
    }
    return self;
}

-(void)awakeFromNib{
    [super awakeFromNib];
//    NSLog(@"awakeFromNib");
    [self initView];
}

#pragma mark 初始化方法，设置默认值
/**
 初始化视图,设置默认值
 */
-(void)initView{
    self.mTableView=[[UITableView alloc]initWithFrame:CGRectMake(0, 0, self.frame.size.width, self.frame.size.height)];
//    NSLog(@"宽度：%f高度：%f",self.frame.size.width, self.frame.size.height);
    self.mTableView.delegate=self;
    self.mTableView.dataSource=self;
    self.mTableView.tableFooterView=[UIView new];
    self.mTableView.separatorStyle = UITableViewCellSeparatorStyleNone;
    [self.mTableView registerNib:[UINib nibWithNibName:@"ExcelViewCell" bundle:nil] forCellReuseIdentifier:@"ExcelViewCell"];
    [self.mTableView registerNib:[UINib nibWithNibName:@"ExcelLockCell" bundle:nil] forCellReuseIdentifier:@"ExcelLockCell"];
    self.mXTableDatas=[NSMutableArray arrayWithCapacity:10];
    self.mYTableDatas=[NSMutableArray arrayWithCapacity:10];
    self.mFristRowDatas=[NSMutableArray arrayWithCapacity:10];
    self.mScrollViewArray=[NSMutableArray arrayWithCapacity:10];
    self.mColumeMaxWidths=[NSMutableArray arrayWithCapacity:10];
    
    self.mContentOffset=CGPointMake(0, 0);
    self.columnTitlte=@"";
    self.textFont=[UIFont systemFontOfSize:17];
    self.fristRowBackGround=RGB(229, 239, 254);
    [self addSubview:self.mTableView];
 }

/**
 显示
 */
-(void)show{
    //判断数据是否合法
    if(_topTableHeadDatas!=nil&&_leftTabHeadDatas!=nil&&_tableDatas!=nil){
        if(_leftTabHeadDatas.count==_tableDatas.count){
            NSMutableArray *columeDatas=[NSMutableArray arrayWithCapacity:10];
            //计算每列最大宽度
            //先塞值
            if(_isColumnTitlte){
                NSMutableArray *columeData=[NSMutableArray arrayWithCapacity:10];
                [columeData addObject:self.columnTitlte];
                [columeData addObjectsFromArray:self.leftTabHeadDatas];
                [columeDatas addObject:columeData];
            }else{
                NSMutableArray *columeData=[NSMutableArray arrayWithCapacity:10];
                [columeData addObject:@""];
                [columeData addObjectsFromArray:self.leftTabHeadDatas];
                [columeDatas addObject:columeData];
            }
            for(int i=0;i<_topTableHeadDatas.count;i++){
                 NSMutableArray *columeData=[NSMutableArray arrayWithCapacity:10];
                [columeData addObject:_topTableHeadDatas[i]];
                for (int j=0; j<_tableDatas.count; j++) {
                    [columeData addObject:_tableDatas[j][i]];
                }
                [columeDatas addObject:columeData];
            }
//            NSLog(@"%@",columeDatas);
            //计算宽度
            for(int i=0;i<columeDatas.count;i++){
                NSArray *columeData=columeDatas[i];
                CGFloat max=0;
                for(int j=0;j<columeData.count;j++){
                    CGFloat value=[UILabel getWidthWithTitle:columeData[j] font:self.textFont];
//                    NSLog(@"第%d列第%d行宽度:%f",i,j,value);
                    if (value>max) {
                        self.mColumeMaxWidths[i]=[NSNumber numberWithDouble:value+10];
                        max=value;
                    }else{
                        self.mColumeMaxWidths[i]=[NSNumber numberWithDouble:max+10];
                    }
                }
            }
//            NSLog(@"mColumeMaxWidths:%@",self.mColumeMaxWidths);
            //构造每行数据
            for (int i=0;i<_tableDatas.count;i++) {
                NSArray *rowArray=_tableDatas[i];
                if(_topTableHeadDatas.count==rowArray.count){
                    if (_isLockFristColumn) {
                        //如果锁定第一列数据
                        [self.mXTableDatas addObject:rowArray];
                    }else{
                        NSString *mFristColumnTitle=[_leftTabHeadDatas objectAtIndex:i];
                        NSMutableArray *newRowArray=[NSMutableArray arrayWithCapacity:10];
                        [newRowArray addObject:mFristColumnTitle];
                        [newRowArray addObjectsFromArray:rowArray];
                        [self.mXTableDatas addObject:newRowArray];
                    }
                }else{
                    NSLog(@"数据非法！第一行表头数据和实际数据项单行数据个数不一致");
                    return;
                }
            }
            //构造第一列和第一行数据
            if(_isLockFristColumn){
                //如果第一列锁定
                if (_isColumnTitlte) {
                    [self.mYTableDatas addObject:_columnTitlte];
                }else{
                    [self.mYTableDatas addObject:@""];
                }
                [self.mYTableDatas addObjectsFromArray:_leftTabHeadDatas];
                //构造第一行数据
                [self.mFristRowDatas addObjectsFromArray:_topTableHeadDatas];
            }else{
                //构造第一行数据
                if (_isColumnTitlte) {
                    [self.mFristRowDatas addObject:_columnTitlte];
                }else{
                    [self.mFristRowDatas addObject:@""];
                }
                [self.mFristRowDatas addObjectsFromArray:_topTableHeadDatas];
            }
            //构造视图
            [self.mTableView reloadData];
        }else{
            NSLog(@"数据非法！第一列表头数据和实际数据项单列数据个数不一致");
            return;
        }
    }else{
        NSLog(@"数据异常，请检查数据是否全部赋值！");
    }
//    //检测数据
//    NSLog(@"第1行数据:%@",_mFristRowDatas);
//    for (int i=0; i<_mXTableDatas.count; i++) {
//        NSLog(@"第%d行数据:%@",i+2,_mXTableDatas[i]);
//    }
//    NSLog(@"第一列数据:%@",self.mYTableDatas);

}



#pragma mark UITableViewDelegate
-(UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath{
    if (_isLockFristRow) {
       //如果锁第一行
        if(_isLockFristColumn){
           //如果锁第一列
            //不要复用cell，要不然cell里视图会成倍复写，这样总scrollView视图数组就会出现问题
            ExcelLockCell *cell=[tableView dequeueReusableCellWithIdentifier:[NSString stringWithFormat:@"%ld",(long)indexPath.row]];
            if (!cell) {
                cell=(ExcelLockCell *)[[[NSBundle mainBundle]loadNibNamed:@"ExcelLockCell" owner:nil options:nil]lastObject];
            }
            //构造锁定视图
            UILabel *lockView=[[UILabel alloc]initWithFrame:CGRectMake(cell.lockView.frame.origin.x, cell.lockView.frame.origin.y,[self.mColumeMaxWidths[0] floatValue]>70?[self.mColumeMaxWidths[0] floatValue]:70, cell.frame.size.height)];
            lockView.text=[self.mYTableDatas objectAtIndex:indexPath.row+1];
            lockView.textAlignment=NSTextAlignmentCenter;
            lockView.textColor=RGB(84, 84, 84);
            lockView.font=self.textFont;
            //更改锁定视图frame
            cell.lockView.frame=CGRectMake(cell.lockView.frame.origin.x, cell.lockView.frame.origin.y,[self.mColumeMaxWidths[0] floatValue]>70?[self.mColumeMaxWidths[0] floatValue]:70, cell.frame.size.height);
            cell.lockViewWidthConstraint.constant=[self.mColumeMaxWidths[0] floatValue]>70?[self.mColumeMaxWidths[0] floatValue]:70;
            [cell.lockView addSubview:lockView];
            cell.lockView.layer.borderWidth=0.6;
            cell.lockView.layer.borderColor=[UIColor groupTableViewBackgroundColor].CGColor;
            //构造滚动视图
            CGFloat x=0;
            int i=1;
            for (NSString *data in [self.mXTableDatas objectAtIndex:indexPath.row]) {
                UIView *view=[[UIView alloc]initWithFrame:CGRectMake(x, 0, [self.mColumeMaxWidths[i]floatValue]>70?[self.mColumeMaxWidths[i]floatValue]:70, 45)];
                UILabel *dataView=[[UILabel alloc]initWithFrame:view.bounds];
                dataView.text=data;
                dataView.textColor=RGB(84, 84, 84);
                dataView.textAlignment=NSTextAlignmentCenter;
                dataView.font=self.textFont;
                [view addSubview:dataView];
                view.layer.borderWidth=0.6;
                view.layer.borderColor=[UIColor groupTableViewBackgroundColor].CGColor;
                [cell.scrollView addSubview:view];
                x+=view.frame.size.width;
                i++;
            }
            cell.scrollView.contentSize=CGSizeMake(x, cell.scrollView.frame.size.height);
            //加入滚动视图数组
            cell.scrollView.delegate=self;
            cell.scrollView.bounces=NO;
            cell.scrollView.contentOffset=self.mContentOffset;
            [self.mScrollViewArray addObject:cell.scrollView];
            return cell;
        }else{
            ExcelViewCell *cell=[tableView dequeueReusableCellWithIdentifier:[NSString stringWithFormat:@"%ld",(long)indexPath.row]];
            if (!cell) {
                cell=[[[NSBundle mainBundle]loadNibNamed:@"ExcelViewCell" owner:nil options:nil]lastObject];
            }
            //构造滚动视图
            CGFloat x=0;
            int i=0;
            for (NSString *data in [self.mXTableDatas objectAtIndex:indexPath.row]) {
                UIView *view=[[UIView alloc]initWithFrame:CGRectMake(x, 0,[self.mColumeMaxWidths[i]floatValue]>70?[self.mColumeMaxWidths[i]floatValue]:70,45)];
                UILabel *dataView=[[UILabel alloc]initWithFrame:view.bounds];
                dataView.text=data;
                dataView.textColor=RGB(84, 84, 84);
                dataView.textAlignment=NSTextAlignmentCenter;
                dataView.font=self.textFont;
                [view addSubview:dataView];
                view.layer.borderWidth=0.6;
                view.layer.borderColor=[UIColor groupTableViewBackgroundColor].CGColor;
                [cell.scrollView addSubview:view];
                x+=view.frame.size.width;
                i++;
            }
            cell.scrollView.contentSize=CGSizeMake(x, cell.scrollView.frame.size.height);
            //加入滚动视图数组
            cell.scrollView.delegate=self;
            cell.scrollView.bounces=NO;
            cell.scrollView.contentOffset=self.mContentOffset;
            [self.mScrollViewArray addObject:cell.scrollView];
             return cell;
        }
    }else{
        //如果不锁第一行
        if(_isLockFristColumn){
            //如果锁第一列
            ExcelLockCell *cell=[tableView dequeueReusableCellWithIdentifier:[NSString stringWithFormat:@"%ld",(long)indexPath.row]];
            if (!cell) {
                cell=(ExcelLockCell *)[[[NSBundle mainBundle]loadNibNamed:@"ExcelLockCell" owner:nil options:nil]lastObject];
            }
            if(indexPath.row==0){
                //构造锁定视图
                UILabel *lockView=[[UILabel alloc]initWithFrame:CGRectMake(cell.lockView.frame.origin.x, cell.lockView.frame.origin.y,[self.mColumeMaxWidths[0] floatValue]>70?[self.mColumeMaxWidths[0] floatValue]:70, cell.frame.size.height)];
                lockView.text=[self.mYTableDatas objectAtIndex:indexPath.row];
                lockView.textColor=RGB(94, 153, 251);
                lockView.textAlignment=NSTextAlignmentCenter;
                lockView.font=self.textFont;
                //更改锁定视图frame
                cell.lockView.frame=CGRectMake(cell.lockView.frame.origin.x, cell.lockView.frame.origin.y,[self.mColumeMaxWidths[0] floatValue]>70?[self.mColumeMaxWidths[0] floatValue]:70, cell.frame.size.height);
                cell.lockViewWidthConstraint.constant=[self.mColumeMaxWidths[0] floatValue]>70?[self.mColumeMaxWidths[0] floatValue]:70;
                [cell.lockView addSubview:lockView];
                cell.lockView.layer.borderWidth=0.6;
                cell.lockView.layer.borderColor=[UIColor whiteColor].CGColor;
                cell.lockView.layer.backgroundColor=self.fristRowBackGround.CGColor;
                //构造滚动视图
                CGFloat x=0;
                int i=1;
                for (NSString *data in self.mFristRowDatas) {
                    UIView *view=[[UIView alloc]initWithFrame:CGRectMake(x, 0, [self.mColumeMaxWidths[i]floatValue]>70?[self.mColumeMaxWidths[i]floatValue]:70, 45)];
                    UILabel *dataView=[[UILabel alloc]initWithFrame:view.bounds];
                    dataView.text=data;
                    dataView.textColor=RGB(94, 153, 251);
                    dataView.textAlignment=NSTextAlignmentCenter;
                    dataView.font=self.textFont;
                    [view addSubview:dataView];
                    view.layer.borderWidth=0.6;
                    view.layer.borderColor=[UIColor whiteColor].CGColor;
                    view.layer.backgroundColor=self.fristRowBackGround.CGColor;
                    [cell.scrollView addSubview:view];
                    x+=view.frame.size.width;
                    i++;
                }
                cell.scrollView.contentSize=CGSizeMake(x, cell.scrollView.frame.size.height);
                //加入滚动视图数组
                cell.scrollView.delegate=self;
                cell.scrollView.bounces=NO;
                cell.scrollView.contentOffset=self.mContentOffset;
                [self.mScrollViewArray addObject:cell.scrollView];
            }else{
                //构造锁定视图
                UILabel *lockView=[[UILabel alloc]initWithFrame:CGRectMake(cell.lockView.frame.origin.x, cell.lockView.frame.origin.y,[self.mColumeMaxWidths[0] floatValue]>70?[self.mColumeMaxWidths[0] floatValue]:70, cell.frame.size.height)];
                lockView.text=[self.mYTableDatas objectAtIndex:indexPath.row];
                lockView.textColor=RGB(84, 84, 84);
                lockView.textAlignment=NSTextAlignmentCenter;
                lockView.font=self.textFont;
                cell.lockView.frame=CGRectMake(cell.lockView.frame.origin.x, cell.lockView.frame.origin.y,[self.mColumeMaxWidths[0] floatValue]>70?[self.mColumeMaxWidths[0] floatValue]:70, cell.frame.size.height);
                cell.lockViewWidthConstraint.constant=[self.mColumeMaxWidths[0] floatValue]>70?[self.mColumeMaxWidths[0] floatValue]:70;
                [cell.lockView addSubview:lockView];
                cell.lockView.layer.borderWidth=0.6;
                cell.lockView.layer.borderColor=[UIColor groupTableViewBackgroundColor].CGColor;
                //构造滚动视图
                CGFloat x=0;
                int i=1;
                for (NSString *data in [self.mXTableDatas objectAtIndex:indexPath.row-1]) {
                    UIView *view=[[UIView alloc]initWithFrame:CGRectMake(x, 0, [self.mColumeMaxWidths[i]floatValue]>70?[self.mColumeMaxWidths[i]floatValue]:70, 45)];
                    UILabel *dataView=[[UILabel alloc]initWithFrame:view.bounds];
                    dataView.text=data;
                    dataView.textColor=RGB(84, 84, 84);
                    dataView.textAlignment=NSTextAlignmentCenter;
                    dataView.font=self.textFont;
                    [view addSubview:dataView];
                    view.layer.borderWidth=0.6;
                    view.layer.borderColor=[UIColor groupTableViewBackgroundColor].CGColor;
                    [cell.scrollView addSubview:view];
                    x+=view.frame.size.width;
                    i++;
                }
                cell.scrollView.contentSize=CGSizeMake(x, cell.scrollView.frame.size.height);
                //加入滚动视图数组
                cell.scrollView.delegate=self;
                cell.scrollView.bounces=NO;
                cell.scrollView.contentOffset=self.mContentOffset;
                [self.mScrollViewArray addObject:cell.scrollView];
            }
            return cell;
        }else{
            ExcelViewCell *cell=[tableView dequeueReusableCellWithIdentifier:[NSString stringWithFormat:@"%ld",(long)indexPath.row]];
            if (!cell) {
                cell=[[[NSBundle mainBundle]loadNibNamed:@"ExcelViewCell" owner:nil options:nil]lastObject];
            }
            if (indexPath.row==0) {
                //构造滚动视图
                CGFloat x=0;
                int i=0;
                for (NSString *data in _mFristRowDatas) {
                    UIView *view=[[UIView alloc]initWithFrame:CGRectMake(x, 0, [self.mColumeMaxWidths[i]floatValue]>70?[self.mColumeMaxWidths[i]floatValue]:70,45)];
                    UILabel *dataView=[[UILabel alloc]initWithFrame:view.bounds];
                    dataView.text=data;
                    dataView.textColor=RGB(94, 153, 251);
                    dataView.textAlignment=NSTextAlignmentCenter;
                    dataView.font=self.textFont;
                    [view addSubview:dataView];
                    view.layer.borderWidth=0.6;
                    view.layer.borderColor=[UIColor whiteColor].CGColor;
                    view.layer.backgroundColor=self.fristRowBackGround.CGColor;
                    [cell.scrollView addSubview:view];
                    x+=view.frame.size.width;
                    i++;
                }
                cell.scrollView.contentSize=CGSizeMake(x, cell.scrollView.frame.size.height);
                //加入滚动视图数组
                cell.scrollView.delegate=self;
                cell.scrollView.bounces=NO;
                cell.scrollView.contentOffset=self.mContentOffset;
                [self.mScrollViewArray addObject:cell.scrollView];
            }else{
                //构造滚动视图
                CGFloat x=0;
                int i=0;
                for (NSString *data in [self.mXTableDatas objectAtIndex:indexPath.row-1]) {
                    UIView *view=[[UIView alloc]initWithFrame:CGRectMake(x, 0, [self.mColumeMaxWidths[i]floatValue]>70?[self.mColumeMaxWidths[i]floatValue]:70,45)];
                    UILabel *dataView=[[UILabel alloc]initWithFrame:view.bounds];
                    dataView.text=data;
                    dataView.textColor=RGB(84, 84, 84);
                    dataView.textAlignment=NSTextAlignmentCenter;
                    dataView.font=self.textFont;
                    [view addSubview:dataView];
                    view.layer.borderWidth=0.6;
                    view.layer.borderColor=[UIColor groupTableViewBackgroundColor].CGColor;
                    [cell.scrollView addSubview:view];
                    x+=view.frame.size.width;
                    i++;
                }
                cell.scrollView.contentSize=CGSizeMake(x, cell.scrollView.frame.size.height);
                //加入滚动视图数组
                cell.scrollView.delegate=self;
                cell.scrollView.bounces=NO;
                cell.scrollView.contentOffset=self.mContentOffset;
                [self.mScrollViewArray addObject:cell.scrollView];
            }
            return cell;
        }
    }
    return nil;
}

-(CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath{
    return 45;
}

-(NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section{
    if (_isLockFristRow) {
        return _leftTabHeadDatas.count;
    }else{
        return _leftTabHeadDatas.count+1;
    }
    return 0;
}

-(void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath{
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
    NSLog(@"%ld",(long)indexPath.row);
}

-(UIView *)tableView:(UITableView *)tableView viewForHeaderInSection:(NSInteger)section{
    if(_isLockFristRow){
        if(_isLockFristColumn){
           //如果第一列锁定
            ExcelLockCell *cell=[[[NSBundle mainBundle]loadNibNamed:@"ExcelLockCell" owner:nil options:nil]lastObject];
            //构造锁定视图
            UILabel *lockView=[[UILabel alloc]initWithFrame:CGRectMake(cell.lockView.frame.origin.x, cell.lockView.frame.origin.y,[self.mColumeMaxWidths[0] floatValue]>70?[self.mColumeMaxWidths[0] floatValue]:70, cell.frame.size.height)];
            lockView.text=[self.mYTableDatas objectAtIndex:0];
            lockView.textColor=RGB(94, 153, 251);
            lockView.textAlignment=NSTextAlignmentCenter;
            lockView.font=self.textFont;
            lockView.frame=CGRectMake(cell.lockView.frame.origin.x, cell.lockView.frame.origin.y,[self.mColumeMaxWidths[0] floatValue]>70?[self.mColumeMaxWidths[0] floatValue]:70, cell.frame.size.height);
            cell.lockViewWidthConstraint.constant=[self.mColumeMaxWidths[0] floatValue]>70?[self.mColumeMaxWidths[0] floatValue]:70;
            [cell.lockView addSubview:lockView];
            cell.lockView.layer.borderWidth=0.6;
            cell.lockView.layer.borderColor=[UIColor whiteColor].CGColor;
            cell.lockView.layer.backgroundColor=self.fristRowBackGround.CGColor;
            //构造滚动视图
            CGFloat x=0;
            int i=1;
            for (NSString *data in self.mFristRowDatas) {
                UIView *view=[[UIView alloc]initWithFrame:CGRectMake(x, 0, [self.mColumeMaxWidths[i] floatValue]>70?[self.mColumeMaxWidths[i] floatValue]:70, 45)];
                UILabel *dataView=[[UILabel alloc]initWithFrame:view.bounds];
                dataView.text=data;
                dataView.textColor=RGB(94, 153, 251);
                dataView.textAlignment=NSTextAlignmentCenter;
                dataView.font=self.textFont;
                [view addSubview:dataView];
                view.layer.borderWidth=0.6;
                view.layer.borderColor=[UIColor whiteColor].CGColor;
                view.layer.backgroundColor=self.fristRowBackGround.CGColor;
                [cell.scrollView addSubview:view];
                x+=view.frame.size.width;
                i++;
            }
            cell.scrollView.contentSize=CGSizeMake(x, cell.scrollView.frame.size.height);
            //加入滚动视图数组
            cell.scrollView.delegate=self;
            cell.scrollView.bounces=NO;
            cell.scrollView.contentOffset=self.mContentOffset;
            [self.mScrollViewArray addObject:cell.scrollView];
            return cell;
        }else{
            ExcelViewCell *cell=[[[NSBundle mainBundle]loadNibNamed:@"ExcelViewCell" owner:nil options:nil]lastObject];
            //构造滚动视图
            CGFloat x=0;
            int i=0;
            for (NSString *data in _mFristRowDatas) {
                UIView *view=[[UIView alloc]initWithFrame:CGRectMake(x, 0, [self.mColumeMaxWidths[i] floatValue]>70?[self.mColumeMaxWidths[i] floatValue]:70,45)];
                UILabel *dataView=[[UILabel alloc]initWithFrame:view.bounds];
                dataView.text=data;
                dataView.textColor=RGB(94, 153, 251);
                dataView.textAlignment=NSTextAlignmentCenter;
                dataView.font=self.textFont;
                [view addSubview:dataView];
                view.layer.borderWidth=0.6;
                view.layer.borderColor=[UIColor whiteColor].CGColor;
                view.layer.backgroundColor=self.fristRowBackGround.CGColor;
                [cell.scrollView addSubview:view];
                x+=view.frame.size.width;
                i++;
            }
            cell.scrollView.contentSize=CGSizeMake(x, cell.scrollView.frame.size.height);
            //加入滚动视图数组
            cell.scrollView.delegate=self;
            cell.scrollView.bounces=NO;
            cell.scrollView.contentOffset=self.mContentOffset;
            [self.mScrollViewArray addObject:cell.scrollView];
            return cell;
        }
    }
    return nil;
}

-(CGFloat)tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section{
    if (_isLockFristRow) {
        return 45;
    }
    return 0;
}

#pragma mark UIScrollViewDelegate
-(void)scrollViewDidScroll:(UIScrollView *)scrollView{
//    NSLog(@"scollView滚动实时位移：%f,%f", scrollView.contentOffset.x, scrollView.contentOffset.y);
    if (scrollView!=self.mTableView) {
        //过滤mTableView
        for (UIScrollView *view in _mScrollViewArray) {
            view.contentOffset=scrollView.contentOffset;
        }
    }
}

-(void)scrollViewDidEndDecelerating:(UIScrollView *)scrollView{
//    NSLog(@"scollView滚动结束位移：%f,%f", scrollView.contentOffset.x, scrollView.contentOffset.y);
    if (scrollView!=self.mTableView) {
        self.mContentOffset=scrollView.contentOffset;
    }
 }




@end