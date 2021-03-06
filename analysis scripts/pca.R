# PCA and investigation of the clustering tendency by the symptom recovery times
# done in the AT cohort of the HACT study. Done separately for acute, sub-acute
# long, PASC and chronic CoV.
# no pre-processing applied since the symptom duration data are anyway on the 
# same scale (days post CoV)

  insert_head()
  
# container list ----
  
  pca <- list()
  
# globals: analysis tables ------
  
  insert_msg('Globals setup')
  
  pca$analysis_tbl <- rec_time[c('north', 'south')] %>% 
    map(~filter(.x, complete.cases(.x))) %>% 
    map(column_to_rownames, 'ID')
  
  ## parallel backend
  
  plan('multisession')
  
# PCA -----
  
  insert_msg('PCA and visualizations')
  
  pca$pca_obj <- pca$analysis_tbl %>% 
    map(reduce_data, 
        kdim = 8, 
        red_fun = 'pca')
  
  pca$pca_obj$north$loadings <- pca$pca_obj$north$loadings %>% 
    mutate(variable = translate_var(variable, dict = hact$dict))
  
  pca$pca_obj$south$loadings <- pca$pca_obj$south$loadings %>% 
    mutate(variable = translate_var(variable, dict = hact$dict))
  
  ## Scree plot
  
  pca$pca_scree_plot <- list(x = pca$pca_obj, 
                             segment_color = globals$hact_colors) %>% 
    pmap(plot,
         type = 'scree', 
         cust_theme = globals$common_theme) %>% 
    map2(c('AT, survey study', 
           'IT, survey study'), 
         ~.x + labs(subtitle = .y))
  
  ## loadings
  
  pca$pca_loadings_plot <- list(x = pca$pca_obj, 
                                plot_subtitle = c('AT, survey study', 
                                                  'IT, survey study'), 
                                point_color = globals$hact_colors) %>% 
    pmap(plot,
         type = 'loadings', 
         cust_theme = globals$common_theme, 
         segment_color = 'gray60')
  
  ## score plots
  
  pca$pca_score_plot <- list(x = pca$pca_obj, 
                             plot_subtitle = c('AT, survey study', 
                                               'IT, survey study'), 
                             point_color = globals$hact_colors) %>% 
    pmap(plot,
         type = 'scores', 
         cust_theme = globals$common_theme)
  
  ## global eigenvector plots
  
  pca$pca_imp_plot <- pca$pca_obj %>% 
    map(~.x$loadings) %>% 
    map(mutate, len = sqrt(comp_1^2 + comp_2^2 + comp_3^2 + comp_4^2 + comp_5^2 + comp_6^2 + comp_7^2 + comp_8^2))
  
  pca$pca_imp_plot <- list(data = pca$pca_imp_plot, 
                           plot_subtitle = c('AT, survey study', 
                                             'IT, survey study'), 
                           fill_scale = as.list(globals$hact_colors)) %>% 
    pmap(plot_top, 
         regulation_variable = 'len', 
         label_variable = 'variable', 
         p_variable = 'comp_1', 
         regulation_level = 0, 
         signif_level = 1.1, 
         top_regulated = 10, 
         plot_title = 'PCA: top 10 important symptoms', 
         x_lab = 'Eigenvector', 
         cust_theme = globals$common_theme)
  
# MDS ----
  
  insert_msg('MDS')
  
  pca$mds_obj <- pca$analysis_tbl %>% 
    map(reduce_data, 
        distance_method = 'euclidean', 
        kdim = 2, 
        red_fun = 'mds')
  
  ## score plot
  
  pca$mds_plot <- list(x = pca$mds_obj, 
                       plot_subtitle = c('AT, survey study', 
                                         'IT, survey study'), 
                       point_color = globals$hact_colors) %>% 
    pmap(plot, 
         type = 'scores', 
         cust_theme = globals$common_theme)
  
# UMAP ----
  
  insert_msg('UMAP')
  
  pca$umap_obj <- pca$analysis_tbl %>% 
    map(reduce_data, 
        distance_method = 'euclidean', 
        kdim = 2, 
        red_fun = 'umap')
  
  ## score plot
  
  pca$umap_plot <- list(x = pca$umap_obj, 
                        plot_subtitle = c('AT, survey study', 
                                          'IT, survey study'), 
                        point_color = globals$hact_colors) %>% 
    pmap(plot, 
         type = 'scores', 
         cust_theme = globals$common_theme)
  
# Clustering tendency -----
  
  insert_msg('Investigating the clustering tendency')

  pca$clust_tend <- list(data.north = pca$analysis_tbl$north, 
                         pca.north = pca$pca_obj$north$component_tbl %>% 
                           select(-observation), 
                         mds.north = pca$mds_obj$north$component_tbl %>% 
                           select(-observation), 
                         umap.north = pca$umap_obj$north$component_tbl %>% 
                           select(-observation), 
                         data.south = pca$analysis_tbl$south, 
                         pca.south = pca$pca_obj$south$component_tbl %>% 
                           select(-observation), 
                         mds.south = pca$mds_obj$south$component_tbl %>% 
                           select(-observation), 
                         umap.south = pca$umap_obj$south$component_tbl %>% 
                           select(-observation)) %>% 
    future_map(get_clust_tendency, 
               n = 200, 
               .options = furrr_options(seed = TRUE))

# END -----
  
  plan('sequential')
  
  insert_tail()