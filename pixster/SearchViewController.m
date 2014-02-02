//
//  SearchViewController.m
//  pixster
//
//  Created by Timothy Lee on 7/30/13.
//  Copyright (c) 2013 codepath. All rights reserved.
//

#import "SearchViewController.h"
#import "UIImageView+AFNetworking.h"
#import "AFNetworking.h"
#import "ImageCell.h"

@interface SearchViewController ()

@property (nonatomic, strong) NSMutableArray *fetchResults;
@property (nonatomic, strong) NSMutableArray *imageResults;
@property (weak, nonatomic) IBOutlet UICollectionView *imageCollection;
@property (nonatomic, assign) float imageSize;
@property (nonatomic, strong) NSString *searchTerm;

- (void)getSearchResults:(NSString *)searchText startingFrom:(int)start;
- (void)addToResults:(NSArray *)results;
- (void)combineResults;
- (void)smaller;
- (void)larger;

@end

@implementation SearchViewController

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        self.title = @"Pixster";
        self.fetchResults = [NSMutableArray array];
        self.imageResults = [NSMutableArray array];
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    self.imageSize = 100;
    [self.imageCollection registerNib:[UINib nibWithNibName:@"ImageCell" bundle:nil] forCellWithReuseIdentifier:@"ImageCell"];
    
    UIBarButtonItem *leftButton = [[UIBarButtonItem alloc] initWithTitle:@"Smaller" style:UIBarButtonItemStyleDone target:self action:@selector(smaller)];
    self.navigationItem.leftBarButtonItem = leftButton;
    
    UIBarButtonItem *rightButton = [[UIBarButtonItem alloc] initWithTitle:@"Larger" style:UIBarButtonItemStyleDone target:self action:@selector(larger)];
    self.navigationItem.rightBarButtonItem = rightButton;
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

//#pragma mark - UITableView data source
//
//- (NSInteger)numberOfSectionsInTableView:(UITableView *)aTableView {
//    // Return the number of sections.
//    return 1;
//}
//
//- (NSInteger)tableView:(UITableView *)aTableView numberOfRowsInSection:(NSInteger)section {
//    return [self.imageResults count];
//}
//
//- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
//    
//    static NSString *CellIdentifier = @"CellIdentifier";
//    
//    // Dequeue or create a cell of the appropriate type.
//    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
//    UIImageView *imageView = nil;
//    const int IMAGE_TAG = 1;
//    if (cell == nil) {
//        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:CellIdentifier];
//        cell.accessoryType = UITableViewCellAccessoryNone;
//        imageView = [[UIImageView alloc] initWithFrame:CGRectMake(0, 0, 300, 300)];
//        imageView.contentMode = UIViewContentModeScaleAspectFill;
//        imageView.tag = IMAGE_TAG;
//        [cell.contentView addSubview:imageView];
//    } else {
//        imageView = (UIImageView *)[cell.contentView viewWithTag:IMAGE_TAG];
//    }
//    
//    // Clear the previous image
//    imageView.image = nil;
//    [imageView setImageWithURL:[NSURL URLWithString:[self.imageResults[indexPath.row] valueForKeyPath:@"url"]]];
//    
//    return cell;
//}
//
//- (float)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
//    return 300;
//}

#pragma mark - UISearchDisplay delegate

- (void)searchDisplayControllerDidBeginSearch:(UISearchDisplayController *)controller {
    [self.imageResults removeAllObjects];
    [self.imageCollection reloadData];
}

- (BOOL)searchDisplayController:(UISearchDisplayController *)controller shouldReloadTableForSearchString:(NSString *)searchString {
    return NO;
}

#pragma mark - UISearchBar delegate

- (void)searchBarSearchButtonClicked:(UISearchBar *)searchBar {
    [searchBar setShowsCancelButton:NO animated:YES];
    NSString * searchText = [searchBar.text stringByAddingPercentEscapesUsingEncoding:NSASCIIStringEncoding];
    [self.fetchResults removeAllObjects];
    [self.imageResults removeAllObjects];
    for (int i=0; i<20; i+=4) {
        [self getSearchResults:searchText startingFrom:i];
    }
    self.searchTerm = searchText;
    [self.view endEditing:YES];
}

- (void)getSearchResults:(NSString *)searchText startingFrom:(int)start {
    NSURL *url = [NSURL URLWithString:[NSString stringWithFormat:@"http://ajax.googleapis.com/ajax/services/search/images?v=1.0&q=%@&start=%d", searchText, start]];
    NSURLRequest *request = [NSURLRequest requestWithURL:url];
    
    AFJSONRequestOperation *operation = [AFJSONRequestOperation JSONRequestOperationWithRequest:request success:^(NSURLRequest *request, NSHTTPURLResponse *response, id JSON) {
        id results = [JSON valueForKeyPath:@"responseData.results"];
        if ([results isKindOfClass:[NSArray class]]) {
            [self.fetchResults addObject:results];
            [self combineResults];
        }
    } failure:nil];
    
    [operation start];
}

- (void)combineResults {
    [self.imageResults removeAllObjects];
    for (NSArray * result in self.fetchResults) {
        [self.imageResults addObjectsFromArray:result];
    }
    [self.imageCollection reloadData];
}

- (void)addToResults:(NSArray *)results {
    @synchronized(self.imageResults) {
        [self.imageResults addObjectsFromArray:results];
    }
}

- (void)searchBarTextDidBeginEditing:(UISearchBar *)searchBar {
    [searchBar setShowsCancelButton:YES animated:YES];
}

- (void)searchBarCancelButtonClicked:(UISearchBar *)searchBar {
    [searchBar setShowsCancelButton:NO animated:YES];
    [self.view endEditing:YES];
}

#pragma mark UICollectionViewDataSource

- (NSInteger)numberOfSectionsInCollectionView:(UICollectionView *)collectionView {
    return 1;
}

- (NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section {
    return self.imageResults.count;
}

- (UICollectionViewCell *)collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath {
    static NSString *CellIdentifier = @"ImageCell";
    UICollectionViewCell *cell = [collectionView dequeueReusableCellWithReuseIdentifier:CellIdentifier forIndexPath:indexPath];
    UIImageView *imageView = [[UIImageView alloc] initWithFrame:CGRectMake(0, 0, self.imageSize, self.imageSize)];
    imageView.contentMode = UIViewContentModeScaleAspectFill;
    [cell.contentView addSubview:imageView];
    [imageView setImageWithURL:[NSURL URLWithString:[self.imageResults[indexPath.row] valueForKeyPath:@"url"]]];
    return cell;
}

- (CGSize)collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout*)collectionViewLayout sizeForItemAtIndexPath:(NSIndexPath *)indexPath {
    return CGSizeMake(self.imageSize, self.imageSize);
}

- (void)smaller {
    BOOL needToReload = self.imageSize > 51 ? YES : NO;
    if (self.imageSize > 151) {
        self.imageSize = 150;
    } else if (self.imageSize > 101) {
        self.imageSize = 100;
    } else if (self.imageSize > 76) {
        self.imageSize = 65;
    } else if (self.imageSize > 61) {
        self.imageSize = 50;
    }
    if (needToReload) {
        [self.imageCollection reloadData];
    }
}

- (void)larger {
    BOOL needToReload = self.imageSize < 299 ? YES : NO;
    if (self.imageSize < 59) {
        self.imageSize = 65;
    } else if (self.imageSize < 99) {
        self.imageSize = 100;
    } else if (self.imageSize < 149) {
        self.imageSize = 150;
    } else if (self.imageSize < 299) {
        self.imageSize = 300;
    }
    if (needToReload) {
        [self.imageCollection reloadData];
    }
}

- (void)scrollViewDidEndDragging:(UIScrollView *)scrollView willDecelerate:(BOOL)decelerate {
    NSInteger currentOffset = scrollView.contentOffset.y;
    NSInteger maximumOffset = scrollView.contentSize.height - scrollView.frame.size.height;
    
    if (maximumOffset - currentOffset <= 100) {
        int curCount = self.imageResults.count;
        for (int i=curCount; i<curCount+20; i+=4) {
            [self getSearchResults:self.searchTerm startingFrom:curCount];
        }
    }
}

@end
